if (-not(Test-Path -Path scripts\script.js)) {
    Write-Host "The script is missing, did you forget to paste your script in the scripts folder ? Did you name it script.js ?"
    exit 1
}

$originalLocation = $PWD

Set-Location scripts

if (-not(Test-Path -Path TestResults)) {
    New-Item TestResults -ItemType Directory
}

$guid = [Guid]::NewGuid().ToString();

k6 run -o json=TestResults\$guid.json -o influxdb=http://localhost:8086/k6 script.js

Set-Location $originalLocation