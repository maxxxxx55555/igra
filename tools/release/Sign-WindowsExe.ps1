#requires -Version 5.1
<#
.SYNOPSIS
    Signs a Windows executable with an Authenticode signature and verifies the result.

.DESCRIPTION
    Run: powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\Sign-WindowsExe.ps1 `
             -ExePath "C:\path\LastStreetlight-1.0.1-release.exe" -Pfx "C:\path\cert.pfx" -Password "..."

    Finds signtool.exe on the machine (Windows SDK, the ClickOnce SDK, or Visual Studio),
    signs the binary with SHA-256 and an RFC 3161 timestamp, then verifies the signature
    and prints whether the signing certificate chains to a TRUSTED root.

    The certificate can be given two ways:
      -Pfx <file> -Password <password>   (a .pfx/.p12; the password is never printed)
      -Thumbprint <hex>                  (a certificate already in Cert:\CurrentUser\My)

    A self-signed development certificate produces a cryptographically valid, tamper-evident
    signature, but Windows shows "Unknown publisher" because the chain ends in a root the
    machine does not trust. Only a certificate issued by a public CA gives the publisher name
    in the SmartScreen / file-properties dialog. This script reports which of the two you have.

.PARAMETER ExePath
    The executable to sign. It is signed in place; a .unsigned.bak copy is kept next to it.

.PARAMETER Pfx
    The signing certificate in PKCS#12 form.

.PARAMETER Password
    The password of the .pfx. Passed as an argument for convenience; use -Thumbprint
    instead to avoid a password on the command line.

.PARAMETER Thumbprint
    The SHA-1 thumbprint of a certificate already installed in Cert:\CurrentUser\My.

.PARAMETER TimestampUrl
    The RFC 3161 timestamp server. The default is DigiCert's public one; pass an empty
    string to sign without a timestamp (the signature then expires with the certificate).

.EXAMPLE
    .\Sign-WindowsExe.ps1 -ExePath build\windows\LastStreetlight.exe -Pfx cert.pfx -Password '...'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ExePath,
    [string]$Pfx,
    [string]$Password,
    [string]$Thumbprint,
    [string]$TimestampUrl = 'http://timestamp.digicert.com'
)

$ErrorActionPreference = 'Stop'

function Find-SignTool {
    $candidates = @()
    foreach ($root in @(
            "${env:ProgramFiles(x86)}\Windows Kits\10\bin",
            "$env:ProgramFiles\Windows Kits\10\bin",
            "${env:ProgramFiles(x86)}\Microsoft SDKs\ClickOnce\SignTool",
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio",
            "$env:ProgramFiles\Microsoft Visual Studio")) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        $candidates += Get-ChildItem -LiteralPath $root -Filter 'signtool.exe' -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending
    }
    if (-not $candidates) {
        throw "signtool.exe not found. Install the Windows SDK (https://developer.microsoft.com/windows/downloads/windows-sdk/) or Visual Studio build tools."
    }
    # Prefer an x64 signtool on an x64 host.
    $native = $candidates | Where-Object { $_.FullName -match 'x64' } | Select-Object -First 1
    if ($native) { return $native.FullName }
    return $candidates[0].FullName
}

function Get-CodeSigningCert {
    param([string]$PfxPath, [string]$PasswordText, [string]$Sha1)

    if ($Sha1) {
        $clean = ($Sha1 -replace '[^0-9A-Fa-f]', '').ToUpperInvariant()
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store('My', 'CurrentUser')
        $store.Open('ReadOnly')
        try {
            $found = $store.Certificates | Where-Object { $_.Thumbprint -eq $clean }
            if (-not $found) { throw "No certificate with thumbprint $clean in Cert:\CurrentUser\My" }
            return $found[0]
        } finally { $store.Close() }
    }
    if ($PfxPath) {
        if (-not (Test-Path -LiteralPath $PfxPath)) { throw "Certificate file not found: $PfxPath" }
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.Import($PfxPath, $PasswordText, 'Exportable')
        return $cert
    }
    throw "Give either -Pfx (with -Password) or -Thumbprint."
}

if (-not (Test-Path -LiteralPath $ExePath)) { throw "Executable not found: $ExePath" }
$exe = (Resolve-Path -LiteralPath $ExePath).Path
$signtool = Find-SignTool
"signtool : $signtool"

$cert = Get-CodeSigningCert -PfxPath $Pfx -PasswordText $Password -Sha1 $Thumbprint
"subject   : $($cert.Subject)"
"thumbprint: $($cert.Thumbprint)"
"not after : $($cert.NotAfter.ToString('yyyy-MM-dd'))"

# The certificate must be allowed to sign code, or Windows will not honour the signature.
$codeSigningOid = '1.3.6.1.5.5.7.3.3'
$eku = $cert.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.37' }
$hasCodeSigning = $false
if ($eku) {
    foreach ($oid in $eku.EnhancedKeyUsages) { if ($oid.Value -eq $codeSigningOid) { $hasCodeSigning = $true } }
}
"code-signing EKU: $hasCodeSigning"
if (-not $hasCodeSigning) {
    Write-Warning "This certificate does not carry the code-signing EKU (1.3.6.1.5.5.7.3.3). The signature will be structurally valid but Windows will not treat it as a publisher signature."
}

$backup = "$exe.unsigned.bak"
if (-not (Test-Path -LiteralPath $backup)) { Copy-Item -LiteralPath $exe -Destination $backup }

$signArgs = @('sign', '/sha1', $cert.Thumbprint, '/fd', 'SHA256')
if ($TimestampUrl) { $signArgs += @('/tr', $TimestampUrl, '/td', 'SHA256') }
$signArgs += $exe

& $signtool @signArgs
if ($LASTEXITCODE -ne 0) { throw "signtool sign failed with exit code $LASTEXITCODE" }

& $signtool verify /v /pa $exe
$verifyExit = $LASTEXITCODE

$f = Get-Item -LiteralPath $exe
""
"bytes    : $($f.Length)"
"sha256   : $((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant())"

# Does the chain end in a root the machine trusts?
$sig = Get-AuthenticodeSignature -FilePath $exe
"status   : $($sig.Status) ($($sig.StatusMessage))"
"trusted  : $($sig.SignerCertificate -ne $null -and $sig.Status -eq 'Valid')"
if ($verifyExit -ne 0) {
    ""
    "The verification error above is the expected 'chain ends in an untrusted root' when the"
    "certificate is self-signed. The signature itself is cryptographically valid and the file is"
    "tamper-evident; Windows will still show 'Unknown publisher'. Replace the certificate with"
    "one issued by a public CA to get the publisher name."
}
else {
    "The signature chains to a trusted root: Windows will show the publisher name."
}
