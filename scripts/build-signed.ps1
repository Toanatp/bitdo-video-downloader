[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TauriArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
Set-Location $repoRoot

& (Join-Path $PSScriptRoot "prepare-shopbitdo-signing-assets.ps1") -TrustStoreLocation CurrentUser

Write-Host ""
Write-Host "Building Bitdo Downloader with Tauri..."
$tauriCli = Join-Path $repoRoot "node_modules\.bin\tauri.cmd"
if (Test-Path -LiteralPath $tauriCli) {
    & $tauriCli build @TauriArgs
}
else {
    & npm exec -- tauri build @TauriArgs
}
$tauriExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "Signing Bitdo Downloader Windows artifacts..."
& (Join-Path $PSScriptRoot "sign-windows-build.ps1") -SkipPrepare
$signExitCode = $LASTEXITCODE
if ($signExitCode -ne 0) {
    exit $signExitCode
}

if ($tauriExitCode -ne 0) {
    Write-Error "Tauri build exited with code $tauriExitCode after producing/signing available Windows artifacts. Check the Tauri build output above, especially updater signing key configuration."
    exit $tauriExitCode
}
