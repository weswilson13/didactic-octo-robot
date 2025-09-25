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
        $new.put("userAccountControl", 546)
    }
    else {
        $new.put("userAccountControl", 544)
    }
    Write-Verbose "committing changes"
    $new.setinfo()
    if ($Passthru) {
        $new.refreshcache()
        $new
    }
} #end function