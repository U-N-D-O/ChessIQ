[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ForwardedArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$privateScript = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\.private\release\scripts\setup_ios_release_secrets.ps1'))
if (-not (Test-Path -LiteralPath $privateScript -PathType Leaf)) {
    throw 'Local-only release helper missing. Create .private/release/scripts/setup_ios_release_secrets.ps1 on this machine.'
}

& $privateScript @ForwardedArgs
exit $LASTEXITCODE