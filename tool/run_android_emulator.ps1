param(
    [string]$AvdName = 'ChessIQ_API_35',
    [switch]$StartOnly
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Get-LocalPropertyValue {
    param(
        [string]$PropertiesPath,
        [string]$Key
    )

    if (-not (Test-Path $PropertiesPath)) {
        return $null
    }

    $match = Select-String -Path $PropertiesPath -Pattern "^$([regex]::Escape($Key))=(.+)$" | Select-Object -First 1
    if (-not $match) {
        return $null
    }

    return $match.Matches[0].Groups[1].Value
}

function Resolve-AndroidSdkRoot {
    param([string]$PropertiesPath)

    $sdkRoot = Get-LocalPropertyValue -PropertiesPath $PropertiesPath -Key 'sdk.dir'
    if ($sdkRoot) {
        return $sdkRoot -replace '\\\\', '\'
    }

    if ($env:ANDROID_SDK_ROOT) {
        return $env:ANDROID_SDK_ROOT
    }

    if ($env:ANDROID_HOME) {
        return $env:ANDROID_HOME
    }

    return Join-Path $env:LOCALAPPDATA 'Android\Sdk'
}

function Resolve-FlutterPath {
    param([string]$PropertiesPath)

    $flutterSdk = Get-LocalPropertyValue -PropertiesPath $PropertiesPath -Key 'flutter.sdk'
    if ($flutterSdk) {
        $candidate = Join-Path ($flutterSdk -replace '\\\\', '\') 'bin\flutter.bat'
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCommand) {
        return $flutterCommand.Source
    }

    throw 'Flutter was not found. Install Flutter or add it to PATH.'
}

function Resolve-SdkToolPath {
    param(
        [string]$SdkRoot,
        [string]$RelativePath,
        [string]$CommandName,
        [string]$MissingMessage
    )

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidate = Join-Path $SdkRoot $RelativePath
    if (Test-Path $candidate) {
        return $candidate
    }

    throw $MissingMessage
}

function Get-RunningAvdDeviceId {
    param(
        [string]$AdbPath,
        [string]$TargetAvd
    )

    $deviceIds = & $AdbPath devices |
        Select-String '^emulator-\d+\s+device$' |
        ForEach-Object { ($_ -split '\s+')[0] }

    foreach ($deviceId in $deviceIds) {
        $runningAvdName = (& $AdbPath -s $deviceId emu avd name 2>$null).Trim()
        if ($runningAvdName -eq $TargetAvd) {
            return $deviceId
        }
    }

    return $null
}

$localPropertiesPath = Join-Path $repoRoot 'android\local.properties'
$sdkRoot = Resolve-AndroidSdkRoot -PropertiesPath $localPropertiesPath
$flutterPath = Resolve-FlutterPath -PropertiesPath $localPropertiesPath
$adbPath = Resolve-SdkToolPath -SdkRoot $sdkRoot -RelativePath 'platform-tools\adb.exe' -CommandName 'adb' -MissingMessage 'adb.exe was not found. Install Android SDK Platform-Tools.'
$emulatorPath = Resolve-SdkToolPath -SdkRoot $sdkRoot -RelativePath 'emulator\emulator.exe' -CommandName 'emulator' -MissingMessage 'emulator.exe was not found. Install Android Emulator in the Android SDK Manager.'

& $adbPath start-server | Out-Null

$deviceId = Get-RunningAvdDeviceId -AdbPath $adbPath -TargetAvd $AvdName
if (-not $deviceId) {
    Write-Host "Starting Android emulator '$AvdName'..."
    Start-Process -FilePath $emulatorPath -ArgumentList @('-avd', $AvdName) | Out-Null
    & $adbPath wait-for-device | Out-Null

    for ($attempt = 0; $attempt -lt 5000 -and -not $deviceId; $attempt++) {
        $deviceId = Get-RunningAvdDeviceId -AdbPath $adbPath -TargetAvd $AvdName
    }

    if (-not $deviceId) {
        throw "Android emulator '$AvdName' did not appear in adb."
    }
}

Write-Host "Using Android device '$deviceId' for AVD '$AvdName'."

if ($StartOnly) {
    return
}

& $flutterPath run -d $deviceId -t lib/main.dart