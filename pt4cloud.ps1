# This is a script that implement an algorithm by the PT4Cloud paper
# https://wwang.github.io/papers/PT4Cloud.pdf
param (
    # The test duration in seconds
    [int]$testDuration = 120
)

function Compare-Distribution($d1, $d2) {
    $d1Avg = [double]($d1 | .\jq.exe -f mean.jq | .\jq.exe -s 'add/length')
    $d2Avg = [double]($d2 | .\jq.exe -f mean.jq | .\jq.exe -s 'add/length')
    $delta = [Math]::Abs($d1Avg - $d2Avg);
    $percentage = $delta / [Math]::Min($d1Avg, $d2Avg);
    $stable = $percentage -lt 0.1;
    return $stable
}

function Get-Distribution($s1Path) {
    $fileContent = Get-Content $s1Path -Encoding utf8 -Raw;
    return $fileContent;
}

function Get-NewTestResultPath() {
    $path = Get-ChildItem -Path .\scripts\TestResults -Filter "*.json" -ErrorAction Stop;
    $path = $path | Sort-Object LastAccessTime;
    $path = $path[-1];
    return ".\scripts\TestResults\$path";
}

$runIteration = $true;

# Step 1 - 1: Execute tests for the app continuously for a short interval I. Let the set of perf. data acquired from these tests be S1.
& "$PSScriptRoot\run-iteration.ps1" $testDuration

# Step 1 - 2: Calcultate the performance distribution d1 from S1.
$distributionPath = Get-NewTestResultPath;
$d1 = Get-Distribution($distributionPath);

while ($runIteration) {
    # Step 2 - 1: Execute the app for another time interval I. Let the set of perf. data from these new tests be S2.
    & "$PSScriptRoot\run-iteration.ps1" $testDuration

    # Combine S1 and S2 into a new sample set S. Calculate performance distribution d2 from S
    $distributionPath = Get-NewTestResultPath;
    $d2 = Get-Distribution($distributionPath);

    # Step 3: Compare d1 and d2 to determine if stable?
    $stable = Compare-Distribution $d1 $d2;
    if (-not($stable)) {
        Write-Host "The distribution is not stable.";
        $d1 = $d1 + $d2;
        $testDuration = $testDuration + $testDuration;
    }
    else {
        $runIteration = $false;
    }
}

Write-Host "The performance distribution is stable."