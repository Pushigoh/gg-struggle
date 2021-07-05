# NOTE: This must be run as admin!
#
function Enable-Read {
  param (
    [string[]]$FilePath
  )

  # https://stackoverflow.com/questions/25779423/powershell-to-set-folder-permissions
  $Acl = Get-Acl $FilePath
  #$everyone = new SecurityIdentifier(WellKnownSidType.WorldSid, null)
  $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule( "Everyone", "Read", "Allow")

  $Acl.SetAccessRule($Ar)
  Set-Acl $FilePath $Acl
  Write-Host "Enabled read permissions on $FilePath"
}

$storeMy = "Cert:\LocalMachine\My"
$storeRoot = "Cert:\LocalMachine\Root"
$outputDir = Resolve-Path $args[0]
$hash = Get-Random

$tmpDir = "$Env:TEMP\$hash"

if (($args.Count -lt 1) -or !(Test-Path $outputDir)) {
  Write-Host "Usage: gencert.ps1 <outputDir>"
  Exit 5
}


# Generate self-signed cert, and key
Write-Host "Generating a self-signed certifcate for gg-struggle..."
$cert = New-SelfSignedCertificate `
  -KeyLength 4096 `
  -DnsName "ggst-game.guiltygear.com", "localhost" `
  -CertStoreLocation $storeMy `
  -KeyLocation $tmpDir `
  -KeyFriendlyName "generated by gg-struggle/tools/gencert.ps1" `
  -KeyDescription "gg-struggle-key" `
  -FriendlyName "gg-struggle" `
  -(Get-Date).AddYears(5) `
  -KeyExportPolicy Exportable `
  -NotAfter (Get-Date).AddYears(69) -KeyusageProperty All -KeyUsage CertSign,CRLSign,DigitalSignature


# Move key to output directory as "gg-struggle.key"
$keyName = Get-ChildItem "$tmpDir\Keys"
$keySrc = "$tmpDir\Keys\$keyName"
$keyDst = "$outputDir\gg-struggle.key"

Write-Host $key
Write-Host "Moving $keySrc to $outputDir\gg-struggle.key"
Move-Item -Path "$keySrc" -Destination "$keyDst" -Force
Enable-Read "$keyDst"

# Copy cert to output directory

$outCert = "$outputDir\gg-struggle.cer"
Export-Certificate -Cert $cert -Type CERT -FilePath "$outCert"
Enable-Read "$outCert"
openssl x509 -notout -

# Install cert from the My store into Root store
$certId = $cert.Thumbprint
Write-Host "Installed $storeRoot\$certId to $storeRoot "
Move-Item -path $storeMy\$certId -Destination $storeRoot

