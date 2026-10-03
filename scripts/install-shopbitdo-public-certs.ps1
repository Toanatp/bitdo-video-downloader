[CmdletBinding()]
param(
    [string]$CertificateDirectory,
    [ValidateSet("LocalMachine", "CurrentUser")]
    [string]$StoreLocation = "LocalMachine"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $CertificateDirectory) {
    $CertificateDirectory = Join-Path $PSScriptRoot "..\src-tauri\certs"
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Normalize-Thumbprint {
    param([Parameter(Mandatory = $true)][string]$Thumbprint)
    return ($Thumbprint -replace "\s", "").ToUpperInvariant()
}

function Import-ExpectedCertificate {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedThumbprint,
        [Parameter(Mandatory = $true)][string]$StoreName,
        [Parameter(Mandatory = $true)][ValidateSet("LocalMachine", "CurrentUser")][string]$Location
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Certificate file not found: $Path"
    }

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($resolvedPath)
    $actual = Normalize-Thumbprint -Thumbprint $certificate.Thumbprint
    $expected = Normalize-Thumbprint -Thumbprint $ExpectedThumbprint

    if ($actual -ne $expected) {
        throw "Certificate thumbprint mismatch for $resolvedPath. Expected $expected but got $actual."
    }

    $store = [System.Security.Cryptography.X509Certificates.X509Store]::new($StoreName, $Location)
    try {
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $existing = $store.Certificates.Find(
            [System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint,
            $expected,
            $false
        )
        if ($existing.Count -lt 1) {
            $store.Add($certificate)
            Write-Host "Imported: $($certificate.Subject) -> $Location\$StoreName ($expected)"
        }
        else {
            Write-Host "Already installed: $($certificate.Subject) -> $Location\$StoreName ($expected)"
        }
    }
    finally {
        $store.Close()
    }
}

if ($StoreLocation -eq "LocalMachine" -and -not (Test-IsAdministrator)) {
    $scriptPath = $PSCommandPath
    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$scriptPath`"",
        "-CertificateDirectory", "`"$CertificateDirectory`"",
        "-StoreLocation", $StoreLocation
    ) -join " "
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs -Wait
    exit $LASTEXITCODE
}

$metadataPath = Join-Path $CertificateDirectory "shopbitdo-certificates.json"
$rootCer = Join-Path $CertificateDirectory "shopbitdo-root.cer"
$codeCer = Join-Path $CertificateDirectory "shopbitdo-code-signing.cer"

if (-not (Test-Path -LiteralPath $metadataPath)) {
    throw "Certificate metadata not found: $metadataPath"
}

$metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json

Import-ExpectedCertificate -Path $rootCer -ExpectedThumbprint $metadata.rootThumbprint -StoreName "Root" -Location $StoreLocation
Import-ExpectedCertificate -Path $codeCer -ExpectedThumbprint $metadata.codeSigningThumbprint -StoreName "TrustedPublisher" -Location $StoreLocation

Write-Host ""
Write-Host "SUCCESS: shopbitdo public certificates are installed and verified for $StoreLocation."
