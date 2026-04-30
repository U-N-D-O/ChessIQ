[CmdletBinding()]
param(
    [string]$Repository,
    [string]$ReleaseTag,
    [string]$BuildName,
    [string]$BuildNumber,
    [Nullable[bool]]$UploadToAppStore
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Require-Command {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$InstallHint
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name is required. $InstallHint"
    }
}

function Get-GitHubRepositoryFromRemote {
    $remoteUrl = (& git remote get-url origin).Trim()
    if ($remoteUrl -match 'github\.com[:/](?<slug>[^/]+/[^/.]+)(?:\.git)?$') {
        return $Matches.slug
    }

    throw "Could not determine the GitHub repository from origin remote: $remoteUrl"
}

function Prompt-Value {
    param(
        [Parameter(Mandatory = $true)][string]$CurrentValue,
        [Parameter(Mandatory = $true)][string]$Prompt
    )

    if ($CurrentValue) {
        return $CurrentValue
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

Require-Command -Name 'git' -InstallHint 'Install Git and retry.'
Require-Command -Name 'gh' -InstallHint 'Install GitHub CLI from https://cli.github.com/ and run gh auth login first.'

& gh auth status | Out-Null

$resolvedRepository = Prompt-Value -CurrentValue $Repository -Prompt 'GitHub repository (owner/name)'
if (-not $resolvedRepository) {
    $resolvedRepository = Get-GitHubRepositoryFromRemote
}

$resolvedReleaseTag = Prompt-Value -CurrentValue $ReleaseTag -Prompt 'Release tag (example: ios-v1.0.0+42)'
$resolvedBuildName = Prompt-Value -CurrentValue $BuildName -Prompt 'Optional build name override (press Enter to skip)'
$resolvedBuildNumber = Prompt-Value -CurrentValue $BuildNumber -Prompt 'Optional build number override (press Enter to skip)'

$shouldUploadToAppStore = if ($null -ne $UploadToAppStore) {
    [bool]$UploadToAppStore
}
else {
    Prompt-YesNo -Prompt 'Upload directly to App Store Connect after the IPA is built?' -DefaultYes $true
}

$workingTreeStatus = (& git status --porcelain).Trim()
if ($workingTreeStatus) {
    throw 'Your git working tree is not clean. Commit or stash your changes before starting a release.'
}

$headCommit = (& git rev-parse HEAD).Trim()

$existingTagCommit = ''
try {
    $existingTagCommit = (& git rev-list -n 1 "refs/tags/$resolvedReleaseTag" 2>$null).Trim()
}
catch {
    $existingTagCommit = ''
}

if (-not $existingTagCommit) {
    & git tag $resolvedReleaseTag | Out-Null
}
elseif ($existingTagCommit -ne $headCommit) {
    throw "Tag $resolvedReleaseTag already exists but does not point to HEAD."
}

& git push origin "refs/tags/$resolvedReleaseTag"

$workflowArgs = @(
    'workflow', 'run', 'build_ios_ipa.yml',
    '--repo', $resolvedRepository,
    '-f', "release_tag=$resolvedReleaseTag",
    '-f', ("upload_to_app_store=" + $shouldUploadToAppStore.ToString().ToLowerInvariant())
)

if ($resolvedBuildName) {
    $workflowArgs += @('-f', "build_name=$resolvedBuildName")
}

if ($resolvedBuildNumber) {
    $workflowArgs += @('-f', "build_number=$resolvedBuildNumber")
}

& gh @workflowArgs | Out-Null

Write-Host ''
Write-Host 'Release workflow started.'
Write-Host "Repository: $resolvedRepository"
Write-Host "Tag: $resolvedReleaseTag"
Write-Host "Upload to App Store Connect: $shouldUploadToAppStore"
Write-Host "Open: https://github.com/$resolvedRepository/actions/workflows/build_ios_ipa.yml"