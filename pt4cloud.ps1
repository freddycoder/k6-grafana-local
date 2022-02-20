# This is a script that implement an algorithm inspired by the PT4Cloud paper
# https://wwang.github.io/papers/PT4Cloud.pdf
param (
    # The test duration in seconds
    [int]$testDuration = 120,
    [string]$outputFileType = "gz"
)

function Compare-Distribution($d1, $d2) {
    $d1Avg = [double]($d1 | .\jq.exe -s 'add/length')
    $d2Avg = [double]($d2 | .\jq.exe -s 'add/length')
    $delta = [Math]::Abs($d1Avg - $d2Avg);
    $percentage = $delta / [Math]::Min($d1Avg, $d2Avg);
    $stable = $percentage -lt 0.1;
    return $stable
}

# Source: https://davewyatt.wordpress.com/2014/04/11/using-object-powershell-version-of-cs-using-statement/
function New-Using {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [AllowNull()]
        [Object]
        $InputObject,
 
        [Parameter(Mandatory = $true)]
        [scriptblock]
        $ScriptBlock
    )
 
    try {
        . $ScriptBlock
    }
    finally {
        if ($null -ne $InputObject -and $InputObject -is [System.IDisposable]) {
            $InputObject.Dispose()
        }
    }
}

function Get-UnGetzipFile($filename) {
    New-Using ($stream = New-Object System.IO.MemoryStream) {
        New-Using ($inputStream = [System.IO.File]::OpenRead($filename)) {
            New-Using ($gzipStream = $gzipStream = New-Object System.IO.Compression.GZipStream ($inputStream, [System.IO.Compression.CompressionMode]::Decompress)) {
                $gzipStream.CopyTo($stream)
            }
        }
        $content = [System.Text.Encoding]::UTF8.GetString($stream.ToArray())
        return $content
    }
}

function Get-Sample($S) {
    return $S | .\jq.exe -f list-duration.jq;
}

function Get-Distribution([string] $s1Path) {
    $fileContent = "";
    if ($s1Path.EndsWith(".gz")) {
        $fileContent = Get-UnGetzipFile $s1Path
    }
    else {
        $fileContent = Get-Content $s1Path -Encoding utf8 -Raw
    }
    Remove-Item $s1Path;
    return $fileContent;
}

function Get-NewTestResultPath($fileExtension) {
    $path = Get-ChildItem -Path .\scripts\TestResults -Filter "*.$fileExtension" -ErrorAction Stop;
    $path = $path | Sort-Object LastAccessTime;
    $path = $path[-1];
    return ".\scripts\TestResults\$path";
}

$runIteration = $true;

# Step 1 - 1: Execute tests for the app continuously for a short interval I. Let the set of perf. data acquired from these tests be S1.
& "$PSScriptRoot\run-iteration.ps1" $testDuration $outputFileType

# Step 1 - 2: Calcultate the performance distribution d1 from S1.
$distributionPath = Get-NewTestResultPath($outputFileType);
$S1 = Get-Distribution($distributionPath);
$d1 = Get-Sample($S1);
$S1 = $null;

while ($runIteration) {
    # Step 2 - 1: Execute the app for another time interval I. Let the set of perf. data from these new tests be S2.
    & "$PSScriptRoot\run-iteration.ps1" $testDuration $outputFileType

    # Combine S1 and S2 into a new sample set S. Calculate performance distribution d2 from S
    $distributionPath = Get-NewTestResultPath($outputFileType);
    $S2 = Get-Distribution($distributionPath);
    $d2 = Get-Sample($S2);
    $S2 = $null;

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
