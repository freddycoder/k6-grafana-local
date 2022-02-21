import { gaussian, gaussianStages, randn_bm } from 'https://raw.githubusercontent.com/freddycoder/k6-gauss/main/gaussian.js'
import { check, sleep } from 'k6';
/*
    This is a k6 test setup class. The goal is to provide a way to setup k6 tests
    for many services at the same time. Each service will have its own VU,
    data, request, and checks.
*/
export class TestSetup {
    constructor() {
        this.testServices = [];
        this.stages = [];
    }

    generateStages(days, hours, minutes, seconds) {
        this.stages = gaussianStages(days, hours, minutes, seconds, t => this.getVUs(t));
    }

    getVUs(t) {
        var vu = 0;
        for (var i = 0; i < this.testServices.length; i++) {
            vu += this.testServices[i].getNbVU(t);
        }
        return vu;
    }

    selectTest(iteration, vu) {
        var testCase = this.testServices[Math.floor(Math.random() * this.testServices.length)];
        return testCase;
    }

    wait(response) {
        var sleepTime = 1000 - response.timings.duration;

        if (sleepTime > 0) {
            sleep(sleepTime / 1000);
        }
    }
}

export class TestService {
    constructor(url, VUFunc, testChecks, requestBody, data, params) {
        this.url = url;
        this.VUFunc = VUFunc;
        this.testChecks = testChecks;
        this.request = requestBody;
        this.data = data;
        this.params = params;
        this.stagesVU = [];
    }

    getNbVU(t) {
        var nbVU = this.VUFunc(t);
        this.stagesVU.push(nbVU);
        return nbVU;
    }

    /*
        This function return a request body as a string.
        The body is generated using the data array.
        When a { is found, the next character is used as a key to get the value from the data array.
    */
    getRequestBody() {
        return this.getFormatStringWithIndex(this.request);
    }

    getUrl() {
        return this.getFormatStringWithIndex(this.url);
    }

    getFormatStringWithIndex(someString) {
        var body = someString;
        // Get a random data row
        var dataRow = this.data[Math.floor(Math.random() * this.data.length)];
        var keyArray = [];
        for (var i = 0; i < body.length; i++) {
            if (body[i] == "{") {
                // Parse the next integer in the string
                i++;
                var key = "";
                // Get the key while the char is a digit
                while (body[i] >= '0' && body[i] <= '9') {
                    key += body[i];
                    i++;
                }
                i++;
                // Get the value
                var keyInt = parseInt(key);
                keyArray.push(keyInt);
            }
        }
        for (var i = 0; i < keyArray.length; i++) {
            var key = keyArray[i];
            var value = dataRow[key];
            body = body.replace("{" + key + "}", value);
        }
        return body;
    }
}