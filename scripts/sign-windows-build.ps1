[CmdletBinding()]
param(
    [string]$ToolkitPath = "C:\Users\vungb\shopbitdo-internal-code-signing",
    [string]$BuildRoot,
    [switch]$SkipPrepare
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# npm can prepend PowerShell 7 module paths while this script runs in Windows PowerShell.
# Keep Authenticode module loading on the Windows PowerShell module path to avoid type-data collisions.
$userWindowsPowerShellModules = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules"
$env:PSModulePath = @(
    $userWindowsPowerShellModules,
    "C:\Program Files\WindowsPowerShell\Modules",
    "C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules"
) -join ";"

if (-not $BuildRoot) {
    $BuildRoot = Join-Path $PSScriptRoot "..\src-tauri\target\release"
}

$signScript = Join-Path $ToolkitPath "sign_app.ps1"
$verifyScript = Join-Path $ToolkitPath "verify_signature.ps1"
if (-not (Test-Path -LiteralPath $signScript)) {
    throw "Missing shopbitdo signing script: $signScript"
}
if (-not (Test-Path -LiteralPath $verifyScript)) {
    throw "Missing shopbitdo verification script: $verifyScript"
}

if (-not $SkipPrepare) {
    & (Join-Path $PSScriptRoot "prepare-shopbitdo-signing-assets.ps1") -ToolkitPath $ToolkitPath -TrustStoreLocation CurrentUser
}

if (-not (Test-Path -LiteralPath $BuildRoot)) {
    throw "Build output directory not found: $BuildRoot"
}

$artifactPatterns = @("*.exe", "*.msi", "*.dll")
$artifacts = foreach ($pattern in $artifactPatterns) {
    Get-ChildItem -LiteralPath $BuildRoot -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch "\\deps\\" -and
            $_.FullName -notmatch "\\incremental\\" -and
            $_.FullName -notmatch "\\build\\" -and
            $_.Name -notmatch "^updater_probe"
        }
}
$artifacts = $artifacts | Sort-Object FullName -Unique

if (-not $artifacts -or $artifacts.Count -eq 0) {
    throw "No Windows build artifacts found under $BuildRoot"
}

foreach ($artifact in $artifacts) {
    Write-Host ""
    $existingSignature = Get-AuthenticodeSignature -FilePath $artifact.FullName
    if ($existingSignature.Status -eq "Valid" -and $existingSignature.SignerCertificate -and $existingSignature.SignerCertificate.Subject -eq "CN=shopbitdo") {
        Write-Host "Already signed and valid: $($artifact.FullName)"
        & $verifyScript -Path $artifact.FullName
        if ($LASTEXITCODE -ne 0) {
            throw "Signature verification failed: $($artifact.FullName)"
        }
        continue
    }

    Write-Host "Signing shopbitdo artifact: $($artifact.FullName)"
    & $signScript -Path $artifact.FullName -StoreLocation CurrentUser
    if ($LASTEXITCODE -ne 0) {
        throw "Signing failed: $($artifact.FullName)"
    }

    & $verifyScript -Path $artifact.FullName
    if ($LASTEXITCODE -ne 0) {
        throw "Signature verification failed: $($artifact.FullName)"
    }
}

Write-Host ""
Write-Host "SUCCESS: Signed and verified $($artifacts.Count) Windows artifact(s)."
