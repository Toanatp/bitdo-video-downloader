[CmdletBinding()]
param(
    [string]$ToolkitPath = "C:\Users\vungb\shopbitdo-internal-code-signing",
    [string]$CertificateOutputDirectory = (Join-Path "C:\Users\vungb\shopbitdo-internal-code-signing" "certificates"),
    [string]$PublicBundleDirectory,
    [ValidateSet("CurrentUser", "LocalMachine")]
    [string]$TrustStoreLocation = "CurrentUser",
    [switch]$ForceNew
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $PublicBundleDirectory) {
    $PublicBundleDirectory = Join-Path $PSScriptRoot "..\src-tauri\certs"
}

$createScript = Join-Path $ToolkitPath "create_shopbitdo_certificates.ps1"
$installScript = Join-Path $ToolkitPath "install_shopbitdo_certificate.ps1"

if (-not (Test-Path -LiteralPath $createScript)) {
    throw "Missing shopbitdo signing toolkit script: $createScript"
}
if (-not (Test-Path -LiteralPath $installScript)) {
    throw "Missing shopbitdo signing toolkit script: $installScript"
}

New-Item -ItemType Directory -Force -Path $CertificateOutputDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $PublicBundleDirectory | Out-Null

$rootCer = Join-Path $CertificateOutputDirectory "shopbitdo-root.cer"
$codeCer = Join-Path $CertificateOutputDirectory "shopbitdo-code-signing.cer"
$codePfx = Join-Path $CertificateOutputDirectory "shopbitdo-code-signing.pfx"
$dpapiPasswordFile = Join-Path $CertificateOutputDirectory "shopbitdo-code-signing.pfx.password.dpapi.txt"

if ($ForceNew -or -not ((Test-Path -LiteralPath $rootCer) -and (Test-Path -LiteralPath $codeCer) -and (Test-Path -LiteralPath $codePfx))) {
    $passwordBytes = New-Object byte[] 48
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($passwordBytes)
        $passwordPlain = [Convert]::ToBase64String($passwordBytes)
    }
    finally {
        $rng.Dispose()
    }
    $securePassword = ConvertTo-SecureString -String $passwordPlain -AsPlainText -Force
    $securePassword | ConvertFrom-SecureString | Set-Content -LiteralPath $dpapiPasswordFile -Encoding ASCII

    if ($ForceNew) {
        & $createScript -OutputDirectory $CertificateOutputDirectory -PfxPassword $securePassword -ForceNew
    }
    else {
        & $createScript -OutputDirectory $CertificateOutputDirectory -PfxPassword $securePassword
    }

    Write-Host "Saved the PFX password as a Windows DPAPI-protected file for this user: $dpapiPasswordFile"
}
else {
    Write-Host "Reusing existing shopbitdo signing assets in $CertificateOutputDirectory"
}

& $installScript -CertificateDirectory $CertificateOutputDirectory -StoreLocation $TrustStoreLocation

$bundledRootCer = Join-Path $PublicBundleDirectory "shopbitdo-root.cer"
$bundledCodeCer = Join-Path $PublicBundleDirectory "shopbitdo-code-signing.cer"
Copy-Item -LiteralPath $rootCer -Destination $bundledRootCer -Force
Copy-Item -LiteralPath $codeCer -Destination $bundledCodeCer -Force

$rootCert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new((Resolve-Path -LiteralPath $bundledRootCer).Path)
$codeCert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new((Resolve-Path -LiteralPath $bundledCodeCer).Path)
$metadata = [ordered]@{
    rootSubject = $rootCert.Subject
    rootThumbprint = ($rootCert.Thumbprint -replace "\s", "").ToUpperInvariant()
    codeSigningSubject = $codeCert.Subject
    codeSigningIssuer = $codeCert.Issuer
    codeSigningThumbprint = ($codeCert.Thumbprint -replace "\s", "").ToUpperInvariant()
    generatedAt = (Get-Date).ToUniversalTime().ToString("o")
    publicCertificateOnly = $true
}
$metadataPath = Join-Path $PublicBundleDirectory "shopbitdo-certificates.json"
$metadata | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $metadataPath -Encoding ASCII

Write-Host ""
Write-Host "shopbitdo signing assets are ready."
Write-Host "Public certificates bundled in: $PublicBundleDirectory"
Write-Host "Root thumbprint:          $($metadata.rootThumbprint)"
Write-Host "Code-signing thumbprint:  $($metadata.codeSigningThumbprint)"
Write-Host "Private PFX remains only in: $codePfx"
