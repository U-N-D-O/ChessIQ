[CmdletBinding()]
param(
    [string]$Repository,
    [string]$AppleTeamId,
    [string]$CertificatePath,
    [string]$CertificatePassword,
    [string]$ProvisioningProfilePath,
    [string]$AppStoreConnectApiKeyPath,
    [string]$AppStoreConnectApiKeyId,
    [string]$AppStoreConnectApiIssuerId,
    [switch]$SkipAppStoreUploadSetup
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

function Prompt-YesNo {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [bool]$DefaultYes = $true
    )

    $suffix = if ($DefaultYes) { '[Y/n]' } else { '[y/N]' }
    $answer = (Read-Host "$Prompt $suffix").Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($answer)) {
        return $DefaultYes
    }

    return $answer -in @('y', 'yes')
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

$resolvedRepository = Prompt-Value -CurrentValue $Repository -Prompt "GitHub repository (owner/name)" 
if (-not $resolvedRepository) {
    $resolvedRepository = Get-GitHubRepositoryFromRemote
}

$resolvedTeamId = Prompt-Value -CurrentValue $AppleTeamId -Prompt 'Apple Team ID'
$resolvedCertificatePath = Prompt-Value -CurrentValue $CertificatePath -Prompt 'Path to Apple Distribution .p12 certificate file'
$resolvedCertificatePassword = Prompt-Value -CurrentValue $CertificatePassword -Prompt 'Password used when exporting the .p12 certificate' -Secret
$resolvedProvisioningProfilePath = Prompt-Value -CurrentValue $ProvisioningProfilePath -Prompt 'Path to App Store provisioning profile (.mobileprovision)'

Require-FilePath -PathValue $resolvedCertificatePath -Label 'Certificate file'
Require-FilePath -PathValue $resolvedProvisioningProfilePath -Label 'Provisioning profile'

$certificateBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $resolvedCertificatePath)))
$provisioningProfileBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $resolvedProvisioningProfilePath)))

Write-Host "Uploading signing secrets to $resolvedRepository ..."
Set-GitHubSecret -Repo $resolvedRepository -Name 'APPLE_TEAM_ID' -Value $resolvedTeamId
Set-GitHubSecret -Repo $resolvedRepository -Name 'APPLE_DISTRIBUTION_CERTIFICATE_BASE64' -Value $certificateBase64
Set-GitHubSecret -Repo $resolvedRepository -Name 'APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD' -Value $resolvedCertificatePassword
Set-GitHubSecret -Repo $resolvedRepository -Name 'APPLE_PROVISIONING_PROFILE_BASE64' -Value $provisioningProfileBase64

$configureUpload = -not $SkipAppStoreUploadSetup.IsPresent
if (-not $SkipAppStoreUploadSetup.IsPresent) {
    $configureUpload = Prompt-YesNo -Prompt 'Do you also want the workflow to upload directly to App Store Connect?' -DefaultYes $true
}

if ($configureUpload) {
    $resolvedApiKeyPath = Prompt-Value -CurrentValue $AppStoreConnectApiKeyPath -Prompt 'Path to App Store Connect API key (.p8)'
    $resolvedApiKeyId = Prompt-Value -CurrentValue $AppStoreConnectApiKeyId -Prompt 'App Store Connect API key ID'
    $resolvedApiIssuerId = Prompt-Value -CurrentValue $AppStoreConnectApiIssuerId -Prompt 'App Store Connect API issuer ID'

    Require-FilePath -PathValue $resolvedApiKeyPath -Label 'App Store Connect API key file'

    $apiKeyBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $resolvedApiKeyPath)))

    Write-Host 'Uploading App Store Connect upload secrets ...'
    Set-GitHubSecret -Repo $resolvedRepository -Name 'APP_STORE_CONNECT_API_KEY_ID' -Value $resolvedApiKeyId
    Set-GitHubSecret -Repo $resolvedRepository -Name 'APP_STORE_CONNECT_API_ISSUER_ID' -Value $resolvedApiIssuerId
    Set-GitHubSecret -Repo $resolvedRepository -Name 'APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64' -Value $apiKeyBase64
}

Write-Host ''
Write-Host 'Done.'
Write-Host "Repository: $resolvedRepository"
Write-Host 'Configured signing secrets:'
Write-Host '- APPLE_TEAM_ID'
Write-Host '- APPLE_DISTRIBUTION_CERTIFICATE_BASE64'
Write-Host '- APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD'
Write-Host '- APPLE_PROVISIONING_PROFILE_BASE64'
if ($configureUpload) {
    Write-Host 'Configured automatic upload secrets:'
    Write-Host '- APP_STORE_CONNECT_API_KEY_ID'
    Write-Host '- APP_STORE_CONNECT_API_ISSUER_ID'
    Write-Host '- APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64'
}
else {
    Write-Host 'Automatic App Store Connect upload was skipped.'
}
Write-Host ''
Write-Host 'Next step:'
Write-Host 'powershell -ExecutionPolicy Bypass -File tool/start_ios_app_store_release.ps1'