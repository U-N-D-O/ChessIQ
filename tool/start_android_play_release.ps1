[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ForwardedArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$privateScript = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\.private\release\scripts\start_android_play_release.ps1'))
if (-not (Test-Path -LiteralPath $privateScript -PathType Leaf)) {
    throw 'Local-only release helper missing. Create .private/release/scripts/start_android_play_release.ps1 on this machine.'
}

& $privateScript @ForwardedArgs
exit $LASTEXITCODE