# k6-grafana-local

Some files to quicly setup k6 with grafana on windows using docker 

## Setup

To deploy grafana inside your docker desktop installation run

```
.\setup.ps1
```

## Run some test

First you need to paste your k6 script inside the ```scripts``` folder and then run.

```
.\run-iteration.ps1
```

## More complexe validation

To do more complexe validation you can use the script ```pt4cloud.ps1```.

```
.\pt4cloud.ps1
```

## Scirpt example

```
import { check, sleep } from 'k6';
import http from 'k6/http';
import { authenticateUsingAzure } from './azure.js'
import { gaussian, gaussianStages, randn_bm } from 'https://raw.githubusercontent.com/freddycoder/k6-gauss/main/gaussian.js'
import { TestSetup, TestService } from './testSetup.js'
import papaparse from 'https://jslib.k6.io/papaparse/5.1.1/index.js';
import { SharedArray } from 'k6/data';

const testSetup = new TestSetup();

const pagesizes = new SharedArray('Page sizes', function () {
  return papaparse.parse(open('./datas/pagesize.csv'), { header: false, delimiter: ";" }).data;
});

testSetup.testServices.push(new TestService(
  'https://www.google.ca/search?q={0}',
  t => gaussian(1, 2)(),
  response => check(response, {
    'status was 200': r => r.status === 200,
    'transaction time OK': r => r.timings.duration < 200
  }),
  "",
  pagesizes,
  data => {
    return {
      headers: {
          'Authorization': 'Bearer ' + data.access_token,
          'Content-Type': 'application/json'
      }
    }
  }
));

testSetup.generateStages(0, 0, 0, parseInt(__ENV.TestDuration));

export let options = {
  stages: testSetup.stages,
  thresholds: {
    'http_req_duration': ['p(95)<100']
  }
};

export function setup () {
    return authenticateUsingAzure(tenantId, clientId, clientSecret, scope, resource);
}

export default function (data) {
  var testCase = testSetup.selectTest(__ITER, __VU);

  var url = testCase.getUrl();

  var params = testCase.params(data);

  var response = http.get(url, params);

  testCase.testChecks(response);

  testSetup.wait(response);
}
```