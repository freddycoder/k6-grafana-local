$originalLocation = $PWD

if (-not(Test-Path -Path .\k6)) {
    git clone https://github.com/grafana/k6
}

if (-not(Test-Path -Path .\jq.exe)) {
    Invoke-WebRequest -Uri https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe -OutFile jq.exe
}

Set-Location k6
git submodule update --init
docker-compose up -d influxdb grafana
Set-Location $originalLocation

Write-Output "The dashboard is available at http://localhost:3000/"
Write-Output "To setup a dashboard quickly, import the dashboard id 2587"
Write-Output "Other dashboard are availlable at https://grafana.com/grafana/dashboards/"

