Function New-LDAPUser {
    <#
        https://petri.com/creating-active-directory-user-accounts-adsi-powershell/
    #>
    [cmdletbinding()]
    Param(
        [parameter(Position = 0, Mandatory)]
        [ValidatePattern("^w+sw+$")]
        [string]$Name,
        [string]$DefaultPassword = "P@ssw0rd",
        [string]$OU = "OU=Employees,DC=Globomantics,DC=Local",
        [hashtable]$Properties,
        [switch]$Disable,
        [switch]$Passthru
    )
    #try to get the OU
    [ADSI]$Parent = "LDAP://$OU"
    #verify the OU exists
    if (-Not $parent.distinguishedname) {
        Write-Warning "Can't find  OU $OU"
        #bail out
        Return
    }
    #split name into two variables
    $firstname, $lastname = $name.split()
    #define samaccountname
    $sam = "{0}{1}" -f $firstname[0], $lastname
    Write-Verbose "Testing if $sam already exists in the domain"
    #test if name already exists in the domain
    [ADSI]$Test = "WinNT://$($env:userdomain)/$sam,user"
    If ($test.ADSPath) {
        Write-Warning "A user with the account name of $sam already exists"
        #bail out
        Return
    }
    Write-Verbose "Creating new user $Name in $OU"
    $new = $parent.Create("user", "CN=$Name")
    $new.put("samaccountname", $sam)
    $new.setinfo()
    Write-Verbose "Setting name properties"
    $new.put("givenname", $firstname)
    $new.put("sn", $lastname)
    $new.put("userprincipalname", "$sam@globomantics.local")
    $new.put("Displayname", $name)
    if ($hash) {
        Write-Verbose "Setting additional properties"
        foreach ($key in $hash.keys) {
            Write-Verbose "...$key"
            #verify property is valid
            Try {
                $new.invokeGet($key)
                $new.put($key, $hash.item($key))
            }
            Catch {
                Write-Warning "$key is not a valid property name"
            }
        }
    }
    Write-Verbose "set initial password"
    $new.setpassword("P@ssw0rd")
    Write-Verbose "force change at next logon"
    $new.Put("pwdLastSet", 0)

    if ($Disable) {
        Write-Verbose "Disabling the account"
        $uac = [useraccountcontrol]::PASSWD_NOTREQD + [useraccountcontrol]::NORMAL_ACCOUNT + [UserAccountControl]::ACCOUNTDISABLE
        $new.put("userAccountControl", $uac)    }
    else {
        $uac = [useraccountcontrol]::PASSWD_NOTREQD + [useraccountcontrol]::NORMAL_ACCOUNT
        $new.put("userAccountControl", $uac)
    }
    Write-Verbose "committing changes"
    $new.setinfo()
    if ($Passthru) {
        $new.refreshcache()
        $new
    }
} #end function

function Get-UACAttributes ($UAC) {
    foreach($enum in [useraccountcontrol].GetEnumNames()) {
        if (($UAC -band [useraccountcontrol]::$enum) -ne 0) { 
            $enum 
        }
    }
}

# Flags that control the behavior of the user account.
[flags()]enum UserAccountControl
{
    # The logon script is executed. 
    SCRIPT = 1

    # The user account is disabled. 
    ACCOUNTDISABLE = 2

    # The home directory is required. 
    HOMEDIR_REQUIRED = 8

    # The account is currently locked out. 
    LOCKOUT = 16

    # No password is required. 
    PASSWD_NOTREQD = 32

    # The user cannot change the password. 
    # Note:  You cannot assign the permission settings of PASSWD_CANT_CHANGE by directly modifying the UserAccountControl attribute. 
    # For more information and a code example that shows how to prevent a user from changing the password see User Cannot Change Password.
    PASSWD_CANT_CHANGE = 64

    # The user can send an encrypted password. 
    ENCRYPTED_TEXT_PASSWORD_ALLOWED = 128

    # This is an account for users whose primary account is in another domain. This account provides user access to this domain but not 
    # to any domain that trusts this domain. Also known as a local user account. 
    TEMP_DUPLICATE_ACCOUNT = 256

    # This is a default account type that represents a typical user. 
    NORMAL_ACCOUNT = 512

    # This is a permit to trust account for a system domain that trusts other domains. 
    INTERDOMAIN_TRUST_ACCOUNT = 2048

    # This is a computer account for a computer that is a member of this domain. 
    WORKSTATION_TRUST_ACCOUNT = 4096

    # This is a computer account for a system backup domain controller that is a member of this domain. 
    SERVER_TRUST_ACCOUNT = 8192

    Unused1 = 16384

    Unused2 = 32768

    # The password for this account will never expire. 
    DONT_EXPIRE_PASSWD = 65536

    # This is an MNS logon account. 
    MNS_LOGON_ACCOUNT = 131072

    # The user must log on using a smart card. 
    SMARTCARD_REQUIRED = 262144

    # The service account (user or computer account) under which a service runs is trusted for Kerberos delegation. Any such service 
    # can impersonate a client requesting the service. 
    TRUSTED_FOR_DELEGATION = 524288

    # The security context of the user will not be delegated to a service even if the service account is set as trusted for Kerberos delegation. 
    NOT_DELEGATED = 1048576

    # Restrict this principal to use only Data Encryption Standard (DES) encryption types for keys. 
    USE_DES_KEY_ONLY = 2097152

    # This account does not require Kerberos pre-authentication for logon. 
    DONT_REQUIRE_PREAUTH = 4194304

    # The user password has expired. This flag is created by the system using data from the Pwd-Last-Set attribute and the domain policy. 
    PASSWORD_EXPIRED = 8388608

    # The account is enabled for delegation. This is a security-sensitive setting; accounts with this option enabled should be strictly 
    # controlled. This setting enables a service running under the account to assume a client identity and authenticate as that user to 
    # other remote servers on the network.
    TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION = 16777216

    PARTIAL_SECRETS_ACCOUNT = 67108864

    USE_AES_KEYS = 134217728
}

  