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
