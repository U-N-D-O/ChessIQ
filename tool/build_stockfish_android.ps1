param(
    [string]$SourceDir,
    [string]$AssetsDir = "android/app/src/main/jniLibs",
    [string]$NdkPath,
    [int]$Jobs = [Environment]::ProcessorCount,
    [string[]]$Abis = @("arm64-v8a", "armeabi-v7a", "x86_64")
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $repoRoot "release_guard.json"
if (-not (Test-Path $configPath)) {
    throw "release_guard.json was not found at $configPath"
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$stockfish = $config.stockfish

$abiMap = @{
    "arm64-v8a"   = @{ Arch = "armv8" }
    "armeabi-v7a" = @{ Arch = "armv7" }
    "x86_64"      = @{ Arch = "x86-64" }
    "x86"         = @{ Arch = "x86-32" }
}

foreach ($abi in $Abis) {
    if (-not $abiMap.ContainsKey($abi)) {
        throw "Unsupported ABI '$abi'. Supported values: $($abiMap.Keys -join ', ')"
    }
}

function Get-LocalProperties {
    $localPropertiesPath = Join-Path $repoRoot "android/local.properties"
    $values = @{}
    if (-not (Test-Path $localPropertiesPath)) {
        return $values
    }

    foreach ($line in Get-Content $localPropertiesPath) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#') -or -not $line.Contains('=')) {
            continue
        }
        $parts = $line.Split('=', 2)
        $values[$parts[0].Trim()] = $parts[1].Trim().Replace('\\', '\')
    }
    return $values
}

function Resolve-AndroidSdk {
    $localProperties = Get-LocalProperties
    $candidates = @(
        $localProperties['sdk.dir'],
        $env:ANDROID_SDK_ROOT,
        $env:ANDROID_HOME,
        (Join-Path $env:LOCALAPPDATA 'Android\Sdk')
    ) | Where-Object { $_ }

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    return $null
}

function Resolve-AndroidNdk([string]$ExplicitNdkPath) {
    $candidates = @()
    if ($ExplicitNdkPath) {
        $candidates += $ExplicitNdkPath
    }
    if ($env:ANDROID_NDK_ROOT) {
        $candidates += $env:ANDROID_NDK_ROOT
    }
    if ($env:ANDROID_NDK_HOME) {
        $candidates += $env:ANDROID_NDK_HOME
    }

    foreach ($candidate in $candidates | Where-Object { $_ }) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    $sdkPath = Resolve-AndroidSdk
    if (-not $sdkPath) {
        throw "Android SDK was not found. Set ANDROID_SDK_ROOT or sdk.dir in android/local.properties."
    }

    $ndkRoot = Join-Path $sdkPath 'ndk'
    if (-not (Test-Path $ndkRoot)) {
        throw "No Android NDK installation was found under $ndkRoot"
    }

    $ndkDirectories = Get-ChildItem $ndkRoot -Directory | Sort-Object Name -Descending
    if (-not $ndkDirectories) {
        throw "No Android NDK installation was found under $ndkRoot"
    }

    return $ndkDirectories[0].FullName
}

function Resolve-GitShell {
    $candidates = [System.Collections.Generic.List[string]]::new()
    foreach ($candidate in @(
            'C:\src\Git\usr\bin\sh.exe',
            'C:\src\Git\bin\sh.exe',
            'C:\src\Git\usr\bin\bash.exe',
            'C:\src\Git\bin\bash.exe',
            'C:\Program Files\Git\usr\bin\sh.exe',
            'C:\Program Files\Git\bin\sh.exe',
            'C:\Program Files\Git\usr\bin\bash.exe',
            'C:\Program Files\Git\bin\bash.exe',
            'C:\Program Files (x86)\Git\usr\bin\sh.exe',
            'C:\Program Files (x86)\Git\bin\sh.exe',
            'C:\Program Files (x86)\Git\usr\bin\bash.exe',
            'C:\Program Files (x86)\Git\bin\bash.exe'
        )) {
        $candidates.Add($candidate)
    }

    $gitCommand = Get-Command git -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($gitCommand) {
        $gitRoot = Split-Path -Parent (Split-Path -Parent $gitCommand.Source)
        foreach ($relative in @('usr\bin\sh.exe', 'bin\sh.exe', 'usr\bin\bash.exe', 'bin\bash.exe')) {
            $candidates.Add((Join-Path $gitRoot $relative))
        }
    }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $shCommand = Get-Command sh -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($shCommand -and $shCommand.Source) {
        return $shCommand.Source
    }

    $bashCommand = Get-Command bash -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($bashCommand -and $bashCommand.Source) {
        return $bashCommand.Source
    }

    throw "Git for Windows shell was not found. Install Git for Windows or add sh.exe to PATH."
}

function Resolve-NdkToolchainBin([string]$ResolvedNdkPath) {
    $prebuiltRoot = Join-Path $ResolvedNdkPath 'toolchains\llvm\prebuilt'
    if (-not (Test-Path $prebuiltRoot)) {
        throw "LLVM toolchain directory was not found under $prebuiltRoot"
    }

    $prebuiltDirectory = Get-ChildItem $prebuiltRoot -Directory | Sort-Object Name | Select-Object -First 1
    if (-not $prebuiltDirectory) {
        throw "No LLVM prebuilt directories were found under $prebuiltRoot"
    }

    $toolchainBin = Join-Path $prebuiltDirectory.FullName 'bin'
    if (-not (Test-Path $toolchainBin)) {
        throw "LLVM toolchain bin directory was not found under $toolchainBin"
    }

    return $toolchainBin
}

function Use-GitShellEnvironment([string]$ShellPath) {
    $shellDirectory = Split-Path -Parent $ShellPath
    $gitRoot = if ((Split-Path -Leaf (Split-Path -Parent $shellDirectory)) -eq 'usr') {
        Split-Path -Parent (Split-Path -Parent $shellDirectory)
    }
    else {
        Split-Path -Parent $shellDirectory
    }

    $pathEntries = [System.Collections.Generic.List[string]]::new()
    $pathEntries.Add($shellDirectory)
    foreach ($relative in @('usr\bin', 'bin', 'cmd')) {
        $candidate = Join-Path $gitRoot $relative
        if (Test-Path $candidate) {
            $pathEntries.Add($candidate)
        }
    }

    $originalPath = $env:PATH
    $originalShell = $env:SHELL
    $env:SHELL = $ShellPath
    $env:PATH = ($pathEntries + @($originalPath)) -join ';'

    return @{ Path = $originalPath; Shell = $originalShell }
}

function Invoke-Step([string[]]$Command, [string]$WorkingDirectory) {
    Write-Host ('+ ' + ($Command -join ' '))
    & $Command[0] $Command[1..($Command.Length - 1)]
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $($Command -join ' ')"
    }
}

function Get-StockfishCheckout([string]$PinnedCommit, [string]$CloneRef) {
    if ($SourceDir) {
        if (-not (Test-Path $SourceDir)) {
            throw "Stockfish source directory does not exist: $SourceDir"
        }
        $resolvedSourceDir = (Resolve-Path $SourceDir).Path
        $head = (git -C $resolvedSourceDir rev-parse HEAD).Trim()
        if ($head -ne $PinnedCommit) {
            throw "Stockfish checkout is at $head, expected pinned commit $PinnedCommit"
        }
        return @{ Path = $resolvedSourceDir; Temporary = $null }
    }

    $temporaryRoot = Join-Path $env:TEMP ("chessiq-stockfish-android-" + [guid]::NewGuid().ToString('N'))
    $checkoutDir = Join-Path $temporaryRoot 'Stockfish'
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null

    Write-Host ('+ git clone --depth 1 --branch ' + $CloneRef + ' ' + $stockfish.repo + ' ' + $checkoutDir)
    git clone --depth 1 --branch $CloneRef $stockfish.repo $checkoutDir
    if ($LASTEXITCODE -ne 0) {
        throw "git clone failed with exit code $LASTEXITCODE"
    }

    Write-Host ('+ git -C ' + $checkoutDir + ' checkout --detach ' + $PinnedCommit)
    git -C $checkoutDir checkout --detach $PinnedCommit
    if ($LASTEXITCODE -ne 0) {
        throw "git checkout failed with exit code $LASTEXITCODE"
    }

    $head = (git -C $checkoutDir rev-parse HEAD).Trim()
    if ($head -ne $PinnedCommit) {
        throw "Cloned Stockfish checkout is at $head, expected $PinnedCommit"
    }

    return @{ Path = $checkoutDir; Temporary = $temporaryRoot }
}

$makeCommand = Get-Command make -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $makeCommand) {
    throw "GNU make was not found on PATH."
}

$resolvedAssetsDir = Join-Path $repoRoot $AssetsDir
New-Item -ItemType Directory -Path $resolvedAssetsDir -Force | Out-Null

$cloneRef = if ($stockfish.tag_ref.StartsWith('refs/tags/')) {
    $stockfish.tag_ref.Substring('refs/tags/'.Length)
}
else {
    $stockfish.tag_ref
}

$checkout = Get-StockfishCheckout -PinnedCommit $stockfish.commit -CloneRef $cloneRef
$sourceRoot = Join-Path $checkout.Path 'src'
$ndkResolved = Resolve-AndroidNdk -ExplicitNdkPath $NdkPath
$ndkArgument = $ndkResolved.Replace('\', '/')
$shellPath = Resolve-GitShell
$originalEnvironment = Use-GitShellEnvironment -ShellPath $shellPath
$toolchainBin = Resolve-NdkToolchainBin -ResolvedNdkPath $ndkResolved
$env:PATH = $toolchainBin + ';' + $env:PATH

try {
    Push-Location $sourceRoot
    foreach ($abi in $Abis) {
        $entry = $abiMap[$abi]

        Write-Host ('+ ' + $makeCommand.Source + ' clean')
        & $makeCommand.Source clean
        if ($LASTEXITCODE -ne 0) {
            throw "make clean failed for $abi"
        }

        Write-Host ('+ ' + $makeCommand.Source + ' -j' + $Jobs + ' build COMP=ndk ARCH=' + $entry.Arch + ' NDK=' + $ndkArgument)
        & $makeCommand.Source ("-j" + $Jobs) build COMP=ndk ("ARCH=" + $entry.Arch) ("NDK=" + $ndkArgument)
        if ($LASTEXITCODE -ne 0) {
            throw "make build failed for $abi"
        }

        $builtBinary = Join-Path $sourceRoot 'stockfish'
        if (-not (Test-Path $builtBinary)) {
            throw "Expected Stockfish binary was not produced for $abi"
        }

        $destinationDir = Join-Path $resolvedAssetsDir $abi
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        $destination = Join-Path $destinationDir 'libstockfish.so'
        Copy-Item $builtBinary $destination -Force
        Write-Host "Copied $abi binary to $destination"
    }
}
finally {
    Pop-Location -ErrorAction SilentlyContinue
    $env:PATH = $originalEnvironment.Path
    if ($null -eq $originalEnvironment.Shell) {
        Remove-Item Env:SHELL -ErrorAction SilentlyContinue
    }
    else {
        $env:SHELL = $originalEnvironment.Shell
    }
    if ($checkout.Temporary) {
        Remove-Item $checkout.Temporary -Recurse -Force -ErrorAction SilentlyContinue
    }
}