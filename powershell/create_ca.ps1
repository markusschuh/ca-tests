# Password of all PFX
$password = ConvertTo-SecureString -AsPlainText -Force -String "secret"

# Directory to store all PFX
$certificateFolder = Join-Path "$env:TEMP" $(New-TemporaryFile)

# Name of the Root CA
$selfSignedCertAuthorityName = "Example Corp Lab CA"

# Name of domain for all services
$domain = "my.internal" 

# List of all services, for which endpoint certificates shall be generated
$services = @{
    Server = "server.$domain"
    Client = "client.$domain"
}

# Main

# Create root certificate
$params = @{
    DnsName = $selfSignedCertAuthorityName
    Subject = $selfSignedCertAuthorityName
    KeyUsage = 'CertSign','CRLSign'
    CertStoreLocation = 'Cert:\CurrentUser\My'
    NotAfter = (Get-Date).AddYears(5)
    KeyAlgorithm = 'RSA'
    KeyLength = 4096
    KeyExportPolicy = 'Exportable'
    HashAlgorithm = 'SHA256'
  }
$rootCA = New-SelfSignedCertificate @params
$rootCAThumbprint = $rootCA.Thumbprint
Write-Verbose "Certificate Thumbprint: $rootCAThumbprint"
  
# ToDo
# Add the rootCA certificate to "Trusted Root Certificates" of all hosts

$params = @{
    Cert = "Cert:\CurrentUser\My\$rootCAThumbprint"
    FilePath = "$certificateFolder\$rootCAThumbprint-CA.pfx"
    Password = $password
}
Export-PfxCertificate @param

# Create certificates for each server, signed by rootCA
foreach($service in $services.Keys) {    
    $params = @{
        DnsName = $services[$service]
        Subject = "$service"
        CertStoreLocation = 'Cert:\CurrentUser\My'
        NotAfter = (Get-date).AddYears(1)
        KeyAlgorithm = 'RSA'
        KeyLength = 2048
        KeyExportPolicy = 'Exportable'
        HashAlgorithm = 'SHA256'
        Signer = $rootCA
      }
    $serverCert = New-SelfSignedCertificate @params
    $serverCertThumbprint = $serverCert.Thumbprint
    Write-Verbose "Certificate Thumbprint: $serverCertThumbprint"
    
    $params = @{
        Cert = "Cert:\CurrentUser\My\$serverCertThumbprint"
        FilePath = "$certificateFolder\$serverCertThumbprint-$server.pfx"
        Password = $password
    }
    Export-PfxCertificate @param
}
