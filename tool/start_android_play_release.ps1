[CmdletBinding()]
param(
    [string]$Repository,
    [string]$ReleaseTag,
    [string]$BuildName,
    [string]$BuildNumber
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Command {
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

function Read-Value {
    param(
        [Parameter(Mandatory = $true)][string]$CurrentValue,
        [Parameter(Mandatory = $true)][string]$Prompt
    )

    if ($CurrentValue) {
        return $CurrentValue
    }

    return (Read-Host $Prompt).Trim()
}

Assert-Command -Name 'git' -InstallHint 'Install Git and retry.'
Assert-Command -Name 'gh' -InstallHint 'Install GitHub CLI from https://cli.github.com/ and run gh auth login first.'

& gh auth status | Out-Null

$resolvedRepository = Read-Value -CurrentValue $Repository -Prompt 'GitHub repository (owner/name)'
if (-not $resolvedRepository) {
    $resolvedRepository = Get-GitHubRepositoryFromRemote
}

$resolvedReleaseTag = Read-Value -CurrentValue $ReleaseTag -Prompt 'Release tag (example: android-v1.0.0+42)'
$resolvedBuildName = Read-Value -CurrentValue $BuildName -Prompt 'Optional build name override (press Enter to skip)'
$resolvedBuildNumber = Read-Value -CurrentValue $BuildNumber -Prompt 'Optional build number override (press Enter to skip)'

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
    'workflow', 'run', 'build_android_aab.yml',
    '--repo', $resolvedRepository,
    '-f', "release_tag=$resolvedReleaseTag"
)

if ($resolvedBuildName) {
    $workflowArgs += @('-f', "build_name=$resolvedBuildName")
}

if ($resolvedBuildNumber) {
    $workflowArgs += @('-f', "build_number=$resolvedBuildNumber")
}

& gh @workflowArgs | Out-Null

$workflowUrl = 'https://github.com/{0}/actions/workflows/build_android_aab.yml' -f $resolvedRepository

Write-Host ''
Write-Host 'Release workflow started.'
Write-Host "Repository: $resolvedRepository"
Write-Host "Tag: $resolvedReleaseTag"
if ($resolvedBuildName) {
    Write-Host "Build name override: $resolvedBuildName"
}
if ($resolvedBuildNumber) {
    Write-Host "Build number override: $resolvedBuildNumber"
}
Write-Host ("Open: {0}" -f $workflowUrl)