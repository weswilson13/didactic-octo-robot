param(
    [Parameter(Mandatory=$true)]
    [string]$identity
    ,
    [Parameter(Mandatory=$false)]
    [string]$PrincipalsAllowedToRetrievePassword='SQLgMSA'
)

# Create Key Distribution Services (KDS) Root Key
# It takes 10 hours for KDS Root Key to propogate. Use -EffectiveTime method vice -EffectiveImmediately
if(-not (Get-KdsRootKey)) {
    Add-kdsRootKey -EffectiveTime ((Get-Date).AddHours(-10)) -Verbose
}

# Create service account
New-ADServiceAccount -Name $identity -DNSHostName (Get-IniContent "$PSScriptRoot\scriptconfig.ini").Values.strDomain

# Verify account creation in Active Directory Administrative Center (ADAC)
# Add machines requiring access to the service account and then restart DC.

# Add principals allowed to retrieve managed password. This restricts the use of Install-ADServiceAccount.
Set-ADServiceAccount -Identity $identity -PrincipalsAllowedToRetrieveManagedPassword $PrincipalsAllowedToRetrievePassword

# Install Service account on target machines
# May need to install Active Directory Module on clients (can use >Install-WindowsFeature rsat)
#Install-ADServiceAccount -Identity svc_iGelUMS