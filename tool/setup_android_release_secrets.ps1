[CmdletBinding()]
param(
    [string]$Repository,
    [string]$KeystorePath,
    [string]$KeystorePassword,
    [string]$KeyAlias,
    [string]$KeyPassword
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PlainTextFromSecureString {
    param([Parameter(Mandatory = $true)][Security.SecureString]$SecureString)

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Get-GitHubRepositoryFromRemote {
    $remoteUrl = (& git remote get-url origin).Trim()
    if ($remoteUrl -match 'github\.com[:/](?<slug>[^/]+/[^/.]+)(?:\.git)?$') {
        return $Matches.slug
    }

    throw "Could not determine the GitHub repository from origin remote: $remoteUrl"
}

function Require-Command {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$InstallHint
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name is required. $InstallHint"
    }
}

function Prompt-Value {
    param(
        [Parameter(Mandatory = $true)][string]$CurrentValue,
        [Parameter(Mandatory = $true)][string]$Prompt,
        [switch]$Secret
    )

    if ($CurrentValue) {
        return $CurrentValue
    }

    if ($Secret) {
        return Get-PlainTextFromSecureString -SecureString (Read-Host $Prompt -AsSecureString)
    }

    return (Read-Host $Prompt).Trim()
}

function Require-FilePath {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $PathValue -PathType Leaf)) {
        throw "$Label was not found: $PathValue"
    }
}

function Set-GitHubSecret {
    param(
        [Parameter(Mandatory = $true)][string]$Repo,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Secret $Name cannot be empty."
    }

    $Value | gh secret set $Name --repo $Repo | Out-Null
}

Require-Command -Name 'git' -InstallHint 'Install Git and retry.'
Require-Command -Name 'gh' -InstallHint 'Install GitHub CLI from https://cli.github.com/ and run gh auth login first.'

& gh auth status | Out-Null

$resolvedRepository = Prompt-Value -CurrentValue $Repository -Prompt 'GitHub repository (owner/name)'
if (-not $resolvedRepository) {
    $resolvedRepository = Get-GitHubRepositoryFromRemote
}

$resolvedKeystorePath = Prompt-Value -CurrentValue $KeystorePath -Prompt 'Path to Android upload keystore (.jks or .keystore)'
$resolvedKeystorePassword = Prompt-Value -CurrentValue $KeystorePassword -Prompt 'Android keystore password' -Secret
$resolvedKeyAlias = Prompt-Value -CurrentValue $KeyAlias -Prompt 'Android key alias'
$resolvedKeyPassword = Prompt-Value -CurrentValue $KeyPassword -Prompt 'Android key password' -Secret

Require-FilePath -PathValue $resolvedKeystorePath -Label 'Android keystore file'

$keystoreBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $resolvedKeystorePath)))

Write-Host "Uploading Android signing secrets to $resolvedRepository ..."
Set-GitHubSecret -Repo $resolvedRepository -Name 'ANDROID_KEYSTORE_BASE64' -Value $keystoreBase64
Set-GitHubSecret -Repo $resolvedRepository -Name 'ANDROID_KEYSTORE_PASSWORD' -Value $resolvedKeystorePassword
Set-GitHubSecret -Repo $resolvedRepository -Name 'ANDROID_KEY_ALIAS' -Value $resolvedKeyAlias
Set-GitHubSecret -Repo $resolvedRepository -Name 'ANDROID_KEY_PASSWORD' -Value $resolvedKeyPassword

Write-Host ''
Write-Host 'Done.'
Write-Host "Repository: $resolvedRepository"
Write-Host 'Configured signing secrets:'
Write-Host '- ANDROID_KEYSTORE_BASE64'
Write-Host '- ANDROID_KEYSTORE_PASSWORD'
Write-Host '- ANDROID_KEY_ALIAS'
Write-Host '- ANDROID_KEY_PASSWORD'
Write-Host ''
Write-Host 'Next step:'
Write-Host 'powershell -ExecutionPolicy Bypass -File tool/start_android_play_release.ps1'