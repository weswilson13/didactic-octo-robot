#region function declarations
function Clear-Console {
    $ADGroupsBox.Visible = $false
    $ADGroupMembershipBox.Visible = $false
    $DisplayInfoBox.ResetText()
    $DisplayInfoBox.Visible = $true
    $DisplayTitleLabel.ResetText()
    $ADGroupsBox.Items.Clear()
    $AddGroupButton.Visible = $false
    $RemoveGroupButton.Visible = $false
    $ADGroupMembershipBox.Items.Clear()
    $ADAccountExpiryDatePicker.Visible = $false
    $ADAccountClearExpiryButton.Visible = $false
    $UpdateExpiryButton.Visible = $false
    $UpdatePasswordButton.Visible = $false
    $NewPasswordTextBox.Visible = $false
    $ExpiryTableLayoutPanel.Visible = $false
}
function Clear-ReportPanel {
    $ADReportsTableLayoutPanel.Visible = $false    
}
function Clear-OptionsPanel {
    $OptionButtonsTableLayoutPanel.Visible = $false
}
function Clear-DomainServersPanel {
    $DomainServersTableLayoutPanel.Visible = $false
}
function Clear-GroupControlsPanel {
    $GroupControlsTableLayoutPanel.Visible = $false
}
function Reset-Form {
    param(
        [switch]$ExceptPrincipal
    )

    if (!$ExceptPrincipal.IsPresent) { $ADPrincipalTextBox.ResetText() }
    $ADGetGroupMembershipButton.Visible = $false
    # $UpdateGroupMembershipsButton.Visible = $false
    $ADAccountStatusLabel.Visible = $false
    $ADAccountExpirationLabel.Visible = $false
    $ADAccountEnableLabel.Visible = $false
    $ADAccountUnlockLabel.Visible = $false
    $ADAccountEnableButton.Visible = $false
    $ADAccountRequiresSmartcardLabel.Visible = $false
    $ADAccountRequiresSmartcardCheckBox.Visible = $false
    $ADAccountActionsLabel.Visible = $false
    $ADAccountSetExpiryButton.Visible = $false
    $ADAccountResetAccountPasswordButton.Visible = $false
    $ADAccountUnlockUserAccountButton.Visible = $false
    $ADReportsTableLayoutPanel.Visible = $false
    $ValidateNPUserButton.Visible = $false
    $OptionButtonsTableLayoutPanel.Visible = $true
    $DomainServersTableLayoutPanel.Visible = $true

    Clear-GroupControlsPanel
    Clear-Console
}
function Get-ConnectionParameters {
    param(
        [string]$IniSection
    )

    # $ini = Get-IniContent .\config.ini

    $encrypt = switch ($ini.$IniSection.Encrypt) {
        {[string]::IsNullOrWhiteSpace($PSItem)} { 'Mandatory'; break }
        {$PSItem -in @('Mandatory', 'Strict', 'Optional')} { $PSItem; break }
        default { throw "Valid values for Encrypt attribute are 'Mandatory', 'Strict', or 'Optional'"}
    }
    $trustServerCertificate = switch ($ini.$IniSection.TrustServerCertificate) {
        'True' { $true; break }
        'False' { $false; break }
        {[string]::IsNullOrWhiteSpace($PSItem)} { $false; break }
        default { throw "Valid values for TrustServerCertificate switch are 'True' or 'False'"}
    }

    return [hashtable]@{
        ServerInstance = $ini.$IniSection.SqlServerInstance
        DatabaseName = $ini.$IniSection.Database
        SchemaName = $ini.$IniSection.Schema
        TableName = $ini.$IniSection.Table
        Encrypt = $encrypt
        TrustServerCertificate = $trustServerCertificate
    }
}
function Import-SessionLog {
    try {
        Write-Host "Importing Session Log"
        
        $connectionParams = Get-ConnectionParameters -IniSection LoggerConfig
        $sessionLog = Import-Csv $env:Temp\LogFile.csv
        $sqlParameters = @{
            InputData = $sessionLog
            ServerInstance = $connectionParams.ServerInstance
            DatabaseName = $connectionParams.DatabaseName
            SchemaName = $connectionParams.SchemaName
            TableName = $connectionParams.TableName
            Encrypt = $connectionParams.Encrypt
            TrustServerCertificate = $connectionParams.TrustServerCertificate
            Force = $true
        }

        Write-Log -Message "Importing Session Logs" -Severity Information
        Write-SqlTableData @sqlParameters

        Remove-Item $env:TEMP\LogFile.csv -Force
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-Log -Message $error[0].Exception.Message -Severity Error
        [System.Windows.MessageBox]::Show("Failed to import session logs.", "Application Logging Failure",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}
function Get-UserMapping {
    param()

    try {
        # $ini = Get-IniContent .\config.ini

        return [PSCustomObject]@{
            First_Name = $ini.UserMappingNPtoAD.First_Name
            Last_Name = $ini.UserMappingNPtoAD.Last_Name
            Rate = $ini.UserMappingNPtoAD.Rate
            PRSGROUP = $ini.UserMappingNPtoAD.PRSGROUP
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-Log -Message $error[0].Exception.Message -Severity Information
    }
}
#region event handlers
function handler_ADLookupButton_Click
  {
    $adParams = @{}
    if ($script:server) { $adParams["Server"] = $script:server }
    
    # reset the form
    Reset-Form -ExceptPrincipal

    try {
        $principal = $ADPrincipalTextBox.Text
        if ($principal) {
            Clear-ReportPanel
            Clear-OptionsPanel 
            Clear-DomainServersPanel
            $Script:objPrincipal = switch ($true) {
                $ADSearchUsersRadioButton.Checked { Get-ADUser @adParams -Identity $principal -Properties *; break } 
                $ADSearchComputersRadioButton.Checked { Get-ADComputer @adParams -Identity $principal -Properties *; break }
                $ADSearchServiceAccountsRadioButton.Checked { Get-ADServiceAccount @adParams -Identity $principal -Properties *;break }
            }

            if ([string]::IsNullOrWhiteSpace($objPrincipal)) {
                Write-Host "ERROR"
                [System.Windows.MessageBox]::Show("Unable to find $principal", "Active Directory Search Failed",`
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
            $DisplayInfoBox.Text = $objPrincipal | Out-String
            $DisplayTitleLabel.Text = "Account Properties"

            # set control values that depend on the AD Object
            $ADAccountEnableLabel.Text = "Account Enabled: $($objPrincipal.Enabled)"
            $ADAccountEnableButton.Text = switch ($objPrincipal.Enabled) {
                $true { "Disable Account";break }
                $false { "Enable Account";break }
            }
            $strExpiry = switch ($objPrincipal.AccountExpirationDate) {
                $null { "N/A";break }
                default { $PSItem.ToString("MM/dd/yyyy") }
            }
            $ADAccountExpirationLabel.Text = "Account Expiry: $strExpiry"
            $ADAccountRequiresSmartcardLabel.Text = "Smartcard Required: $($objPrincipal.SmartcardLogonRequired)"
            $ADAccountRequiresSmartcardCheckBox.Checked = $objPrincipal.SmartcardLogonRequired
            $ADAccountUnlockLabel.Text = "Account Locked Out: $($objPrincipal.LockedOut)"

            $ADGetGroupMembershipButton.Visible=$true
            $ADAccountActionsLabel.Visible = $true

            if ($objPrincipal.ObjectClass -in @('user','msDS-GroupManagedServiceAccount')) {
                $ADAccountExpiryDatePicker.Value = switch($objPrincipal.AccountExpirationDate) {
                    $null { $ADAccountExpiryDatePicker.MaxDate }
                    default { $PSItem }
                }
                $ADAccountStatusLabel.Visible = $true
                $ADAccountExpirationLabel.Visible = $true
                $ADAccountEnableLabel.Visible = $true
                $ADAccountUnlockLabel.Visible = $true
                $ADAccountEnableButton.Visible = $true
                $ADAccountSetExpiryButton.Visible = $true
                $ADAccountUnlockUserAccountButton.Visible = $true
                $ADAccountUnlockUserAccountButton.Enabled = $objPrincipal.LockedOut
                $ADAccountResetAccountPasswordButton.Visible = $true
                if ($objPrincipal.ObjectClass -eq 'user') {
                    $ValidateNPUserButton.Visible = $true
                    $ADAccountRequiresSmartcardLabel.Visible = $true
                    $ADAccountRequiresSmartcardCheckBox.Visible = $true
                }
            }
            Write-Log -Message "$env:USERNAME looked up account properties for $($objPrincipal.SamAccountName)" -Severity Information
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
        [System.Windows.MessageBox]::Show("Unable to find $principal", "Active Directory Search Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } 
  }
function handler_ADSearchComputersRadioButton_Click
{   
    Write-Host "Computers Radio Button Pressed"
    Reset-Form
    $ADUserLabel.Text = "Enter a computer name"
    $ADLookupButton.Text = "Lookup Computer"
}
function handler_ADSearchUsersRadioButton_Click
{
    Write-Host "Users Radio Button Pressed"
    Reset-Form
    $ADUserLabel.Text = "Enter a username"
    $ADLookupButton.Text = "Lookup User"
}

function handler_ADSearchServiceAccountsRadioButton_Click
{
    Write-Host "ServiceAccounts Radio Button Pressed"
    Reset-Form
    $ADUserLabel.Text = "Enter a sMSA/gMSA"
    $ADLookupButton.Text = "Lookup Service Account"
}
function handler_ADGetGroupMembershipButton_Click
{
    try {
        Write-Host "Get Group Memberships"
        Clear-Console
        if ($objPrincipal) {
            $DisplayInfoBox.Visible=$false
            $DisplayTitleLabel.Text = "Group Membership"
            $ADGroupsBox.Visible = $true
            $RemoveGroupButton.Visible = $true
            $AddGroupButton.Visible = $true
            $ADGroupMembershipBox.Visible = $true
            $GroupControlsTableLayoutPanel.Visible = $true
            Get-ADGroup -Filter 'GroupScope -ne "DomainLocal" -and Name -ne "Domain Users"' | 
            Where-Object { $_.DistinguishedName -notin $objPrincipal.MemberOf } | 
            ForEach-Object {
                $ADGroupsBox.Items.Add($PSItem.Name)
            }
            $objPrincipal.MemberOf.ForEach({$ADGroupMembershipBox.Items.Add((Get-ADGroup $PSItem).SamAccountName)})
            Write-Log -Message "$env:USERNAME enumerated group membership for $($objPrincipal.SamAccountName)" -Severity Information
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
    }
}
function handler_AddGroupButton_Click 
{
    $group = $ADGroupsBox.SelectedItems
    if ($group) {
        [System.Collections.ArrayList]$tmpADGroupsBox = @()
        $tmpADGroupsBox.AddRange($ADGroupsBox.Items) 
        $tmpADGroupsBox = $tmpADGroupsBox | Where-Object { $_ -notin $group }

        $group | Foreach-Object {
            $ADGroupMembershipBox.Items.Add($PSItem) 
        }

        $ADGroupsBox.Items.Clear()
        $ADGroupsBox.Items.AddRange($tmpADGroupsBox)

        $UpdateGroupMembershipsButton.Visible = $true 
    }
}

function handler_RemoveGroupButton_Click
{
    $group = $ADGroupMembershipBox.SelectedItems
    if ($group) {
        [System.Collections.ArrayList]$tmpADGroupMembershipBox = @()
        $tmpADGroupMembershipBox.AddRange($ADGroupMembershipBox.Items) 
        $group.foreach({$tmpADGroupMembershipBox.Remove($PSItem)})
    
        $group | Foreach-Object {
            $ADGroupsBox.Items.Add($PSItem) 
        }

        $ADGroupMembershipBox.Items.Clear()
        $ADGroupMembershipBox.Items.AddRange($tmpADGroupMembershipBox)

        $UpdateGroupMembershipsButton.Visible = $true 
    }
}

function handler_UpdateGroupMembershipButton_Click
{
    try {
        $memberGroups = $objPrincipal.MemberOf.ForEach({Get-ADGroup -Filter "DistinguishedName -eq '$PSItem'"})
        $removedGroups = @()
        $addedGroups = @()

        # remove groups
        $groupsToRemove = $memberGroups | Where-Object { $_.SamAccountName -notin $ADGroupMembershipBox.Items }
        $groupsToRemove | ForEach-Object {
            Write-Host "Removed $($objPrincipal.SamAccountName) from $($PSItem.SamAccountName)"
            $removedGroups += "  {0}" -f $PSItem.SamAccountName
            $PSItem | Remove-ADGroupMember -Members $objPrincipal -Confirm:$false -ErrorAction Stop
        }
        
        # add groups
        $ADGroupMembershipBox.Items.Where({ $_ -notin $memberGroups.SamAccountName }) | ForEach-Object {
            $group = Get-ADGroup $PSItem 
            Write-Host "Added $($objPrincipal.SamAccountName) to $($group.SamAccountName)"
            $addedGroups += "  {0}" -f $group.SamAccountName
            $group | Add-ADGroupMember -Members $objPrincipal -Confirm:$false -ErrorAction Stop
        }
        
        $message = "Finished modifying group membership for $($objPrincipal.SamAccountName).`n"
        if ($removedGroups) {
            $message = $message + "`nRemoved $($objPrincipal.SamAccountName) from the following groups:`n$($removedGroups | Out-String)"
        }
        if ($addedGroups) {
            $message = $message + "`nAdded $($objPrincipal.SamAccountName) to the following groups:`n$($addedGroups | Out-String)"
        }

        # update the AD object variable
        $Script:objPrincipal = Get-ADUser $objPrincipal -Properties *

        [System.Windows.MessageBox]::Show($message, "Group Membership Update Success",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        
        Write-Log -Message "$env:USERNAME $($message.Replace('Finished modifying', 'modified'))" -Severity Information
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
        [System.Windows.MessageBox]::Show($error[0].Exception.Message, "Group Membership Update Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function handler_ADAccountEnableButton_Click
{
    try {
        # Set-ADUser $objPrincipal -Enabled (!$objPrincipal.Enabled) -Confirm:$false
        $action = switch ($objPrincipal.Enabled) {
            # $true { Disable-ADAccount $objPrincipal -Confirm:$false;break }
            # $false { Enable-ADAccount $objPrincipal -Confirm:$false;break }
            $true { "Disable" }
            $false { "Enable" }
        }

        $message = "Are you sure you want to $($action.ToLower()) $($objPrincipal.SamAccountName)?"
        $ans = [System.Windows.MessageBox]::Show($message, "Verify Action",`
            [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
        if ($ans -eq "Yes") {
            Invoke-Expression "$action-ADAccount `$objPrincipal -Confirm:`$false"

            $script:objPrincipal = Get-ADUser $objPrincipal -Properties *
            $ADAccountEnableButton.Text = switch($objPrincipal.Enabled) {
                $true { "Disable Account";break }
                $false { "Enable Account";break }
            }
            Write-Host $ADAccountEnableButton.Text
            $ADAccountEnableLabel.Text = "Account Enabled: $($objPrincipal.Enabled)"

            $state = switch($objPrincipal.Enabled) {
                $true { "Enabled";break }
                $false { "Disabled";break }
            }

            [System.Windows.MessageBox]::Show("Account was $state. Please wait ~30 seconds for Active Directory to reflect the change.", "Account Enable/Disable Success",`
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
                Write-Log -Message "$env:USERNAME $state account $($objPrincipal.SamAccountName)" -Severity Information
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
        [System.Windows.MessageBox]::Show("Unable to update account", "Account Enable/Disable Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function handler_ADAccountRequiresSmartCardCheckbox_Click 
{
    try {
        $currentState = switch($objPrincipal.SmartcardLogonRequired) {
            $true { "Disable";break }
            $false { "Enable";break }
        }
        $ans = [System.Windows.MessageBox]::Show("$currentState SmartcardLogonRequired for $($objPrincipal.SamAccountName)?", "Toggle SmartcardLogonRequired Attribute",`
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($ans -eq "Yes") {
            Set-ADUser $objPrincipal -SmartcardLogonRequired (!$objPrincipal.SmartcardLogonRequired)
     
            $script:objPrincipal = Get-ADUser $objPrincipal -Properties *
  
            $state = switch($objPrincipal.SmartcardLogonRequired) {
                $true { "Enabled";break }
                $false { "Disabled";break }
            }

            [System.Windows.MessageBox]::Show("SmartcardLogonRequired was $state. Please wait ~30 seconds for Active Directory to reflect the change.", "Toggle SmartcardLogonRequired Attribute",`
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        
                Write-Log -Message "$env:USERNAME $state SmartcardLogonRequired for account $($objPrincipal.SamAccountName)" -Severity Information
        }
        if ($ans -eq "No") {
            $ADAccountRequiresSmartcardCheckBox.Checked = $false
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
        [System.Windows.MessageBox]::Show("Unable to update account", "SmartcardLogonRequired Enable/Disable Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function handler_ADAccountExpiryButton_Click
{
    Clear-Console
    $DisplayInfoBox.Visible = $false
    $DisplayTitleLabel.Text = "Modify Account Expiration Date"
    $ExpiryTableLayoutPanel.Visible = $true
    $ADAccountExpiryDatePicker.Visible = $true
    $ADAccountClearExpiryButton.Visible = $true
    $ADAccountClearExpiryButton.Enabled = $objPrincipal.AccountExpirationDate -ne $null
    $UpdateExpiryButton.Visible = $true
}

function handler_ADAccountClearExpiryButton_Click 
{
    try {
        Write-Host "Clear Expiry Button Clicked"
        $ans = [System.Windows.MessageBox]::Show("Clear Account Expiration?", "Verify Action",`
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($ans -eq "Yes") {
            Clear-ADAccountExpiration $objPrincipal
            [System.Windows.MessageBox]::Show("Account Expiration cleared. Please wait ~30 seconds for Active Directory to reflect the change.", "Success",`
                [System.Windows.MessageBoxButton]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
            Write-Log -Message "$env:USERNAME cleared Account Expiration for account $($objPrincipal.SamAccountName)" -Severity Information

            $DisplayInfoBox.Visible = $true
            $DisplayTitleLabel.Text = "Account Properties"
            $ExpiryTableLayoutPanel.Visible = $false
            $ADAccountClearExpiryButton.Visible = $false
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
        [System.Windows.MessageBox]::Show("Unable to clear account expiration", "Expiry update Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function handler_UpdateExpiryButton_Click
{
    try {
        Write-Host "Update Expiry Button Clicked"
            $expiry = $ADAccountExpiryDatePicker.Text
            $ans = [System.Windows.MessageBox]::Show("Set Account Expiration to $($expiry)?", "Verify Action",`
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($ans -eq "Yes") {
                Set-ADAccountExpiration $objPrincipal -DateTime $expiry
                [System.Windows.MessageBox]::Show("Updated Account Expiration Date. Please wait ~30 seconds for Active Directory to reflect the change.", "Success",`
                    [System.Windows.MessageBoxButton]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

                Write-Log -Message "$env:USERNAME changed account expiration date for account $($objPrincipal.SamAccountName)" -Severity Information

                $DisplayInfoBox.Visible = $true
                $DisplayTitleLabel.Text = "Account Properties"
                $ADAccountExpiryDatePicker.Visible = $false
                $UpdateExpiryButton.Visible = $false
                $ADAccountClearExpiryButton.Visible = $false
                $ExpiryTableLayoutPanel.Visible = $false
            }
        # }
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
        [System.Windows.MessageBox]::Show("Unable to update account expiration", "Account update Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}
 #region Reports Error Handlers
function handler_ADReportsDisabledComputersButton_Click
{
        Write-Host "Get DisabledComputers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Disabled Computers"
        $DisplayInfoBox.Text = (Get-DisabledComputers | Format-Table -AutoSize | Out-String)
}

function handler_ADReportsDomainControllersButton_Click
{
        Write-Host "Get DomainControllers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Domain Controllers"
        $DisplayInfoBox.Text = (Get-DomainControllers | Format-Table -AutoSize | Out-String)
}

function handler_ADReportsInactiveComputersButton_Click
{
        Write-Host "Get InactiveComputers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Inactive Computers"
        $DisplayInfoBox.Text = (Get-InactiveComputers | Format-Table -AutoSize | Out-String)
}

function handler_ADReportsInactiveUsersButton_Click
{
        Write-Host "Get InactiveUsers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Inactive Users"
        # $user = Get-InactiveUsers | Out-GridView -Title 'Inactive Users' -PassThru
        # $ADPrincipalTextBox.Text = $user.SamAccountName
        Get-InactiveUsers
        $DisplayInfoBox.Text = (Import-Csv $env:TEMP\InactiveUsers.csv) | Out-String
}

function handler_ADReportsLockedOutUsersButton_Click
{
        Write-Host "Get LockedOutUsers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Locked Out Users"
        $DisplayInfoBox.Text = (Get-LockedOutUsers | Format-Table -AutoSize | Out-String)
}

function handler_ADReportsUsersNeverLoggedOnButton_Click
{
        Write-Host "Get UsersNeverLoggedOn Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Never Logged On"
        $DisplayInfoBox.Text = (Get-UsersNeverLoggedOn | Format-Table -AutoSize | Out-String)
}

function handler_ADReportsUsersRecentlyCreatedButton_Click
{
        Write-Host "Get UsersRecentlyCreated Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Recently Created"
        $DisplayInfoBox.Text = (Get-UsersRecentlyCreated | Format-Table -AutoSize | Out-String)
}

function handler_ADReportsUsersRecentlyDeletedButton_Click
{
        Write-Host "Get UsersRecentlyDeleted Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Recently Deleted"
        $DisplayInfoBox.Text = (Get-UsersRecentlyDeleted | Format-Table -AutoSize | Out-String)
}

function handler_ADReportsUsersRecentlyModifiedButton_Click
{
        Write-Host "Get Users Recently Modified Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Recently Modified"
        $DisplayInfoBox.Text = (Get-UsersRecentlyModified | Format-Table -AutoSize | Out-String)
}

function handler_ADReportsUsersWithoutManagerButton_Click
{
        Write-Host "Get Users Without Manager Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Without Manager"
        $DisplayInfoBox.Text = (Get-UsersWithoutManager | Format-Table -AutoSize | Out-String)
}
#endregion

function handler_ADAccountUnlockUserAccountButton_Click
{
    try {
        Write-Host "Unlock User Account Button Clicked"
        $ans = [System.Windows.MessageBox]::Show("Unlock $($objPrincipal.SamAccountName)?", "Verify Action",`
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($ans -eq "Yes") {
            Unlock-UserAccount -Identity $objPrincipal

            [System.Windows.MessageBox]::Show("Account unlocked.", "Unlock Account",`
                [System.Windows.MessageBoxButton]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)  
        
            Write-Log -Message "$env:USERNAME unlocked account $($objPrincipal.SamAccountName)" -Severity Information
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
        [System.Windows.MessageBox]::Show("Unable to unlock account", "Account Unlock Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function handler_ADAccountResetAccountPasswordButton_Click
{
    Write-Host "Reset account password button clicked"
    Clear-Console
    Clear-Console
    $DisplayInfoBox.Visible = $false
    $DisplayTitleLabel.Text = "Reset Account Password"
    $ExpiryTableLayoutPanel.Visible = $true
    $NewPasswordTextBox.Visible = $true
    $UpdatePasswordButton.Visible = $true
}

function handler_UpdatePasswordButton_Click
{
    try {
        Write-Host "Update Password Button Clicked"
        $ans = [System.Windows.MessageBox]::Show("Reset Password for $($objPrincipal.SamAccountName)?", "Verify Action",`
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($ans -eq "Yes") {
            $newPassword = ConvertTo-SecureString $NewPasswordTextBox.Text -AsPlainText -Force
            Set-AccountPassword -Identity $objPrincipal -NewPassword $newPassword

            [System.Windows.MessageBox]::Show("Password Reset Successfully.", "Reset Password",`
                [System.Windows.MessageBoxButton]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
            Write-Log -Message "$env:USERNAME reset password for account $($objPrincipal.SamAccountName)" -Severity Information
            
            Clear-Console
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
        [System.Windows.MessageBox]::Show("Unable to reset password", "Password Reset Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function handler_DisplayReportsPanelButton_Click
{
    $OptionButtonsTableLayoutPanel.Visible = $false
    $ADReportsTableLayoutPanel.Visible = $true
}

function handler_ValidateNPUserButton_Click
{
    try {
        Write-Host "Validate Notepad User"
        
        $connectionParams = Get-ConnectionParameters -IniSection NotepadDbConfig

        $sqlParameters = @{
            ServerInstance = $connectionParams.ServerInstance
            Database = $connectionParams.DatabaseName
            Encrypt = $connectionParams.Encrypt
            TrustServerCertificate = $connectionParams.TrustServerCertificate
        }
        
        #region get the users PID from NOTEPAD
        # first get the AD attributes used to identify the user from the [UserMappingNPtoAD] section in config.ini
        $mapping = Get-UserMapping

        # get the PID query from the [NotepadDbConfig] section in config.ini
        $ini = Get-IniContent .\config.ini 
        $pidQuery = $ini.NotepadDbConfig.PIDQuery
        
        # update the PID query with the AD attributes
        $pidQuery = $pidQuery.replace('<firstname>', $objPrincipal.$($mapping.First_Name))
        $pidQuery = $pidQuery.replace('<lastname>', $objPrincipal.$($mapping.Last_Name))
        $pidQuery = $pidQuery.replace('<rate>', $objPrincipal.$($mapping.Rate))
        Write-Verbose $pidQuery
        $sqlParameters["Query"] = $pidQuery

        # execute the query
        $_PID = Invoke-Sqlcmd @sqlParameters
        if (!$_PID) { throw "A PID for user $($objPrincipal.SamAccountName) was not found in NOTEPAD." }
        #endregion PID Query

        #region update the login id in Notepad
        # get the update query from the [NotepadDbConfig] section in config.ini
        $updateQuery = $ini.NotepadDbConfig.UpdateQuery

        # update the query for the specific user
        $updateQuery = $updateQuery.Replace('<username>', $objPrincipal.UserPrincipalName)
        $updateQuery = $updateQuery.Replace('<pid>', $_PID.PID)
        Write-Verbose $updateQuery
        $sqlParameters["Query"] = $updateQuery
        
        # execute the query
        Invoke-Sqlcmd @sqlParameters
        #endregion Update NP user

        $logMessage = "$env:USERNAME validated $($objPrincipal.SamAccountName) against NOTEPAD database.`n"
        $logMessage += "Updated WinLogonID to $($objPrincipal.UserPrincipalName) for the PID $($_PID.PID)."
        
        [System.Windows.MessageBox]::Show($logMessage, "NP User Validation",`
                    [System.Windows.MessageBoxButton]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

        Write-Log -Message $logMessage -Severity Information
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
        [System.Windows.MessageBox]::Show("Unable to validate user against NOTEPAD", "NOTEPAD Validation Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function handler_formclose
  {
    1..3 | ForEach-Object {[GC]::Collect()}
    
    Write-Log -Message "$env:USERNAME ended the session." -Severity Information 
    
    $form.Dispose()

    Import-SessionLog
}
#endregion

#dot sourced functions
. "$PSScriptRoot\Functions\Set-NTKGroups.ps1"
. "$PSScriptRoot\Functions\Write-Log.ps1"
. "$PSScriptRoot\Functions\Get-DisabledComputers.ps1"
. "$PSScriptRoot\Functions\Get-DomainControllers.ps1"
. "$PSScriptRoot\Functions\Get-InactiveComputers.ps1"
. "$PSScriptRoot\Functions\Get-InactiveUsers.ps1"
. "$PSScriptRoot\Functions\Get-LockedOutUsers.ps1"
. "$PSScriptRoot\Functions\Get-UsersNeverLoggedOn.ps1"
. "$PSScriptRoot\Functions\Get-UsersRecentlyCreated.ps1"
. "$PSScriptRoot\Functions\Get-UsersRecentlyDeleted.ps1"
. "$PSScriptRoot\Functions\Get-UsersRecentlyModified.ps1"
. "$PSScriptRoot\Functions\Get-UsersWithoutManager.ps1"
. "$PSScriptRoot\Functions\Set-AccountPassword.ps1"
. "$PSScriptRoot\Functions\Unlock-UserAccount.ps1"
#endregion

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class ProcessDPI {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SetProcessDPIAware();
}
'@

$null = [ProcessDPI]::SetProcessDPIAware()

Import-Module ActiveDirectory,PSIni
Import-Module SqlServer -MinimumVersion 22.0.0

#load config
$script:ini = Get-IniContent .\config.ini

#region font objects
$TitleFont = New-Object System.Drawing.Font("Calibri",24,[Drawing.FontStyle]::Bold)
# $BodyFont = New-Object System.Drawing.Font("Calibri",18,[Drawing.FontStyle]::Bold)
$BoxFont = New-Object System.Drawing.Font("Calibri", 12, [Drawing.FontStyle]::Regular)
$BoldBoxFont = New-Object System.Drawing.Font("Calibri", 12, [Drawing.FontStyle]::Bold)
$ConsoleFont = New-Object System.Drawing.Font("Lucida Console", 9, [Drawing.FontStyle]::Regular)
#endregion

####################################################
# FORM CONTROLS
####################################################
#region create the controls
#region configure individual controls
#region lookup principal
#region Username label
$objParams = @{
    TypeName = 'System.Windows.Forms.Label'
    Property = @{
        Text = "Enter a Username"
        AutoSize = $true
        Font = $BoldBoxFont
    }
}
$ADUserLabel = New-Object @objParams
#endregion

#region Username input textbox
$objParams = @{
    TypeName = 'System.Windows.Forms.TextBox'
    Property = @{
        Width = 150 # $form.Width * 0.3
        Height = 15
        Name = "ADUserInput"
        Font = $BoxFont
        Multiline = $false
    }
}
$ADPrincipalTextBox = New-Object @objParams
#endregion

#region Lookup User Button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADLookupButton"
        Text = "Lookup User"
        Font = $BoxFont
        AutoSize = $true
        AutoSizeMode = "GrowAndShrink"
        UseVisualStyleBackColor = $True
    }
}
$ADLookupButton = New-Object @objParams
$ADLookupButton.add_Click({handler_ADLookupButton_Click})
#endregion
#endregion lookup principal

#region search type choices (user, computer, service account)
#region search type label
$objParams = @{
    TypeName = 'System.Windows.Forms.Label'
    Property = @{
        Text = "Search Type"
        Font = $BoldBoxFont
        AutoSize = $true
    }
}
$ADSearchTypeLabel = New-Object @objParams
#endregion

#region user search radiobutton
$objParams = @{
    TypeName = 'System.Windows.Forms.RadioButton'
    Property = @{
        Name = "ADUserSearchUsersRadioButton"
        Text = "Users"
        Font = $BoxFont
        Checked = $true
        UseVisualStyleBackColor = $True
    }
}
$ADSearchUsersRadioButton = New-Object @objParams
$ADSearchUsersRadioButton.add_Click({handler_ADSearchUsersRadioButton_Click})
#endregion

#region computer search radiobutton
$objParams = @{
    TypeName = 'System.Windows.Forms.RadioButton'
    Property = @{
        Name = "ADUserSearchComputersRadioButton"
        Text = "Computers"
        Font = $BoxFont
        Checked = $false
        UseVisualStyleBackColor = $True
    }
}
$ADSearchComputersRadioButton = New-Object @objParams
$ADSearchComputersRadioButton.add_Click({handler_ADSearchComputersRadioButton_Click})
#endregion

#region service account search radiobutton
$objParams = @{
    TypeName = 'System.Windows.Forms.RadioButton'
    Property = @{
        Name = "ADUserSearchServiceAccountsRadioButton"
        Text = "Service Accounts"
        Font = $BoxFont
        AutoSize = $true
        Checked = $false
        UseVisualStyleBackColor = $True
    }
}
$ADSearchServiceAccountsRadioButton = New-Object @objParams
$ADSearchServiceAccountsRadioButton.add_Click({handler_ADSearchServiceAccountsRadioButton_Click})
#endregion
#endregion search type choices

#region option button panel controls (Display Report panel, Validate NP User)
#region Option Buttons Label
$objParams = @{
    TypeName = 'System.Windows.Forms.Label'
    Property = @{
        Name = "OptionButtonsLabel"
        Text = "Other Options"
        Font = $BoldBoxFont
        AutoSize = $true
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
    }
}
$OptionButtonsLabel = New-Object @objParams
#endregion

#region display report panel button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "DisplayReportsPanelButton"
        Text = "Active Directory Reports"
        Font = $BoxFont
        AutoSize = $true
    }
}
$DisplayReportsPanelButton = New-Object @objParams
$DisplayReportsPanelButton.add_Click({handler_DisplayReportsPanelButton_Click})
#endregion

#region validate NP user button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ValidateNPUserButton"
        Text = "Validate Notepad User"
        Font = $BoxFont
        AutoSize = $true
    }
}
$ValidateNPUserButton = New-Object @objParams
$ValidateNPUserButton.add_Click({handler_ValidateNPUserButton_Click})
#endregion
#endregion option button panel controls

#region reports controls
#region AD Reports Label
$objParams = @{
    TypeName = 'System.Windows.Forms.Label'
    Property = @{
        Name = "ADReportsLabel"
        Text = "Active Directory Reports"
        Font = $BoldBoxFont
        AutoSize = $true
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
    }
}
$ADReportsLabel = New-Object @objParams
#endregion

#region AD Reports DisabledComputers button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADReportsDisabledComputersButton"
        Text = "Get Disabled Computers"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADReportsDisabledComputersButton = New-Object @objParams
$ADReportsDisabledComputersButton.add_Click({handler_ADReportsDisabledComputersButton_Click})
#endregion

#region AD Reports DomainControllers button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADReportsDomainControllersButton"
        Text = "Get Domain Controllers"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADReportsDomainControllersButton = New-Object @objParams
$ADReportsDomainControllersButton.add_Click({handler_ADReportsDomainControllersButton_Click})
#endregion

#region AD Reports InactiveComputers button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADReportsInactiveComputersButton"
        Text = "Get Inactive Computers"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADReportsInactiveComputersButton = New-Object @objParams
$ADReportsInactiveComputersButton.add_Click({handler_ADReportsInactiveComputersButton_Click})
#endregion

#region AD Reports InactiveUsers button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADReportsInactiveUsersButton"
        Text = "Get Inactive Users"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADReportsInactiveUsersButton = New-Object @objParams
$ADReportsInactiveUsersButton.add_Click({handler_ADReportsInactiveUsersButton_Click})
#endregion

#region AD Reports LockedOutUsers button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADReportsLockedOutUsersButton"
        Text = "Get Locked Out Users"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADReportsLockedOutUsersButton = New-Object @objParams
$ADReportsLockedOutUsersButton.add_Click({handler_ADReportsLockedOutUsersButton_Click})
#endregion

#region AD Reports UsersNeverLoggedOn button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADReportsUsersNeverLoggedOnButton"
        Text = "Get Users Never Logged On"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADReportsUsersNeverLoggedOnButton = New-Object @objParams
$ADReportsUsersNeverLoggedOnButton.add_Click({handler_ADReportsUsersNeverLoggedOnButton_Click})
#endregion

#region AD Reports UsersRecentlyCreated button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADReportsUsersRecentlyCreatedButton"
        Text = "Get Users Recently Created"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADReportsUsersRecentlyCreatedButton = New-Object @objParams
$ADReportsUsersRecentlyCreatedButton.add_Click({handler_ADReportsUsersRecentlyCreatedButton_Click})
#endregion

#region AD Reports UsersRecentlyDeleted button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADReportsUsersRecentlyDeletedButton"
        Text = "Get Users Recently Deleted"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADReportsUsersRecentlyDeletedButton = New-Object @objParams
$ADReportsUsersRecentlyDeletedButton.add_Click({handler_ADReportsUsersRecentlyDeletedButton_Click})
#endregion

#region AD Reports UsersRecentlyModified button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADReportsUsersRecentlyModifiedButton"
        Text = "Get Users Recently Modified"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADReportsUsersRecentlyModifiedButton = New-Object @objParams
$ADReportsUsersRecentlyModifiedButton.add_Click({handler_ADReportsUsersRecentlyModifiedButton_Click})
#endregion

#region AD Reports UsersWithoutManager button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADReportsUsersWithoutManagerButton"
        Text = "Get Users Without Manager"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADReportsUsersWithoutManagerButton = New-Object @objParams
$ADReportsUsersWithoutManagerButton.add_Click({handler_ADReportsUsersWithoutManagerButton_Click})
#endregion
#endregion reports controls

#region account status labels
#region Account Status Label
$objParams = @{
    TypeName = 'System.Windows.Forms.Label'
    Property = @{
        Name = "ADAccountStatusLabel"
        Text = "Account Status"
        Font = $BoldBoxFont
        AutoSize = $true
    }
}
$ADAccountStatusLabel = New-Object @objParams
#endregion

#region Account Expiration Label
$objParams = @{
    TypeName = 'System.Windows.Forms.Label'
    Property = @{
        Name = "ADAccountExpirationLabel"
        Text = "Account Expiration Date: "
        Font = $BoxFont
        AutoSize = $true
    }
}
$ADAccountExpirationLabel = New-Object @objParams
#endregion

#region Account Enabled Label
$objParams = @{
    TypeName = 'System.Windows.Forms.Label'
    Property = @{
        Name = "ADAccountEnabledLabel"
        Text = "Account Enabled: $($objPrincipal.Enabled)"
        Font = $BoxFont
        AutoSize = $true
    }
}
$ADAccountEnableLabel = New-Object @objParams
#endregion

#region Account Locked Label
$objParams = @{
    TypeName = 'System.Windows.Forms.Label'
    Property = @{
        Name = "ADAccountUnlockedLabel"
        Text = "Account Locked Out: $($objPrincipal.LockedOut)"
        Font = $BoxFont
        AutoSize = $true
    }
}
$ADAccountUnlockLabel = New-Object @objParams
#endregion

#region smartcard logon required Label
$objParams = @{
    TypeName = 'System.Windows.Forms.Label'
    Property = @{
        Name = "ADAccountSmartcardRequiredLabel"
        Text = "Smartcard Required: $($objPrincipal.SmartcardLogonRequired)"
        Font = $BoxFont
        AutoSize = $true
    }
}
$ADAccountRequiresSmartcardLabel = New-Object @objParams
#endregion
#endregion account status labels

#region console controls (Display title, Display text box)
#region Display title Label
$objParams = @{
    TypeName = 'System.Windows.Forms.Label'
    Property = @{
        Name = "DisplayTitleLabel"
        Font = $TitleFont
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
    }
}
$DisplayTitleLabel = New-Object @objParams
#endregion

#region Display text box
$objParams = @{
    TypeName = 'System.Windows.Forms.RichTextBox'
    Property = @{
        Name = "DisplayInfoBox"
        Multiline = $true
        Scrollbars = "Both"
        Readonly = $true
        Font = $ConsoleFont
# $DisplayInfoBox.Font = [System.Drawing.Font]::new($BoxFont.FontFamily, $BoxFont.Size-2, $BoxFont.Style)
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
    }
}
$DisplayInfoBox = New-Object @objParams
#endregion
#endregion console controls

#region account actions (modify expiry, reset pwd, unlock account, enable/disable account, smartcardlogon, group membership)
#region account actions label
$objParams = @{
    TypeName = 'System.Windows.Forms.Label'
    Property = @{
        Name = "ADAccountActionsLabel"
        Text = "Account Actions"
        Font = $BoldBoxFont
        AutoSize = $true
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
    }
}
$ADAccountActionsLabel = New-Object @objParams
#endregion

#region modify expiry
#region account expiry button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADAccountSetExpiryButton"
        Text = "Modify Expiry"
        Font = $BoxFont
        AutoSize = $true
    }
}
$ADAccountSetExpiryButton = New-Object @objParams
$ADAccountSetExpiryButton.add_Click({hander_ADAccountExpiryButton_Click})
#endregion

#region Account expiry datepicker
$objParams = @{
    TypeName = 'System.Windows.Forms.DateTimePicker'
    Property = @{
        Name = "ADAccountExpiryDatePicker"
        Font = $BoxFont
        Format = "Custom"
        CustomFormat = "ddd, dd MMM yyyy"
    }
}
$ADAccountExpiryDatePicker = New-Object @objParams
#endregion

#region account clear expiry button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADAccountClearExpiryButton"
        Text = "Clear Account Expiry"
        Font = $BoxFont
        AutoSize = $true
    }
}
$ADAccountClearExpiryButton = New-Object @objParams
$ADAccountClearExpiryButton.add_Click({handler_ADAccountClearExpiryButton_Click})
#endregion

#region update expiry button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "UpdateExpiryButton"
        Text = "Update Expiry"
        Font = $BoxFont
        AutoSize = $true
    }
}
$UpdateExpiryButton = New-Object @objParams
$UpdateExpiryButton.add_Click({handler_UpdateExpiryButton_Click})
#endregion
#endregion

#region reset user password
#region AD Reset Account Password button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADReportsAccountPasswordButton"
        Text = "Reset Account Password"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADAccountResetAccountPasswordButton = New-Object @objParams
$ADAccountResetAccountPasswordButton.add_Click({handler_ADAccountResetAccountPasswordButton_Click})
#endregion

#region New Password Text Box
$objParams = @{
    TypeName = 'System.Windows.Forms.TextBox'
    Property = @{
        Name = "NewPasswordTextBox"
        Font = $BoxFont
        PasswordChar = "*"
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
    }
}
$NewPasswordTextBox = New-Object @objParams
#endregion

#region Update Password Button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "UpdatePasswordButton"
        Text = "Reset Password"
        Font = $BoxFont
        AutoSize = $true
    }
}
$UpdatePasswordButton = New-Object @objParams
$UpdatePasswordButton.add_Click({handler_UpdatePasswordButton_Click})
#endregion
#endregion

#region Enable/Disable Account button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADAccountEnableButton"
        Text = switch ($objPrincipal.Enabled) {
            $true { "Disable Account";break }
            $false { "Enable Account";break }
        }
        Font = $BoxFont
        AutoSize = $true
    }
}
$ADAccountEnableButton = New-Object @objParams
$ADAccountEnableButton.add_Click({handler_ADAccountEnableButton_Click})
#endregion

#region AD Unlock User Account button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADReportsUnlockUserAccountButton"
        Text = "Unlock Account"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADAccountUnlockUserAccountButton = New-Object @objParams
$ADAccountUnlockUserAccountButton.add_Click({handler_ADAccountUnlockUserAccountButton_Click})
#endregion

#region Account requires smartcard checkbox
$objParams = @{
    TypeName = 'System.Windows.Forms.CheckBox'
    Property = @{
        Name = "ADAccountRequiresSmartcard"
        Text = "SmartcardLogonRequired"
        Font = $BoxFont
        AutoSize = $true
        Checked = $objPrincipal.SmartcardLogonRequired
        UseVisualStyleBackColor = $True
    }
}
$ADAccountRequiresSmartcardCheckBox = New-Object @objParams
$ADAccountRequiresSmartcardCheckBox.add_Click({handler_ADAccountRequiresSmartCardCheckbox_Click})
#endregion

#region group membership
#region Enumerate group memberships Button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADGetGroupMembershipButton"
        Text = "Get Group Membership"
        Font = $BoxFont
        AutoSize = $true
        UseVisualStyleBackColor = $True
    }
}
$ADGetGroupMembershipButton = New-Object @objParams
$ADGetGroupMembershipButton.add_Click({handler_ADGetGroupMembershipButton_Click})
#endregion

#region AD Groups List box
$objParams = @{
    TypeName = 'System.Windows.Forms.ListBox'
    Property = @{
        Name = "ADGroupsBox"
        Font = $BoxFont
        SelectionMode = "MultiExtended"
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
    }
}
$ADGroupsBox = New-Object @objParams
#endregion

#region RemoveGroups button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "RemoveGroupButton"
        Text = "<-"
        Font = $BoxFont
        Anchor = [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
    }
}
$RemoveGroupButton = New-Object @objParams
$RemoveGroupButton.add_Click({handler_RemoveGroupButton_Click})
#endregion

#region AddGroups button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "AddGroupButton"
        Text = "->"
        Font = $BoxFont
        Anchor = [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
    }
}
$AddGroupButton = New-Object @objParams
$AddGroupButton.add_Click({handler_AddGroupButton_Click})
#endregion

#region AD Group Membership List box
$objParams = @{
    TypeName = 'System.Windows.Forms.ListBox'
    Property = @{
        Name = "ADGroupMembershipBox"
        Font = $BoxFont
        SelectionMode = "MultiExtended"
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
    }
}
$ADGroupMembershipBox = New-Object @objParams
#endregion

#region Update group memberships Button
$objParams = @{
    Typename = 'System.Windows.Forms.Button'
    Property = @{
        Name = "UpdateGroupMembershipsButton"
        Text = "Update Membership"
        Font = $BoxFont
        AutoSize = $true
        UseVisualStyleBackColor = $true
    }
}
$UpdateGroupMembershipsButton = New-Object @objParams
$UpdateGroupMembershipsButton.add_Click({handler_UpdateGroupMembershipButton_Click})
#endregion
#endregion group membership
#endregion account actions

#region NTK controls
#region NTK label
$objParams = @{
    TypeName = 'System.Windows.Forms.Label'
    Property = @{
        Name = "NTKLabel"
        Text = "Need-To-Know Assignments"
        Font = $BoldBoxFont
        AutoSize = $true
    }
}
$NTKLabel = New-Object @objParams
#endregion NTK label

#region No NTK radiobutton
$objParams = @{
    TypeName = 'System.Windows.Forms.RadioButton'
    Property = @{
        Name = "NoNTKRadioButton"
        Text = "None (Exam/Comp Accounts)"
        Font = $BoxFont
        AutoSize = $true
    }
}
$NoNTKRadioButton = New-Object @objParams
#endregion No NTK radiobutton

#region NonNuclear NTK radiobutton
$objParams = @{
    TypeName = 'System.Windows.Forms.RadioButton'
    Property = @{
        Name = "NonNuclearNTKRadioButton"
        Text = 'Non-Nuclear Trained (DTS, DTP)'
        Font = $BoxFont
        AutoSize = $true
    }
}
$NonNuclearNTKRadioButton = New-Object @objParams
#endregion NonNuclear NTK radiobutton

#region Nuclear NTK radiobutton
$objParams = @{
    TypeName = 'System.Windows.Forms.RadioButton'
    Property = @{
        Name = "NuclearNTKRadioButton"
        Text = 'Nuclear Trained (NPS, NFAS)'
        Font = $BoxFont
        AutoSize = $true
    }
}
$NuclearNTKRadioButton = New-Object @objParams
#endregion Nuclear NTK radiobutton

#region ISD NTK radiobutton
$objParams = @{
    TypeName = 'System.Windows.Forms.RadioButton'
    Property = @{
        Name = "IsdNTKRadioButton"
        Text = "Information Security (ISD)"
        Font = $BoxFont
        AutoSize = $true
    }
}
$IsdNTKRadioButton = New-Object @objParams
#endregion ISD NTK radiobutton

#region Security NTK radiobutton
$objParams = @{
    TypeName = 'System.Windows.Forms.RadioButton'
    Property = @{
        Name = "SecurityNTKRadioButton"
        Text = "Physical Security (ATO, DAD, CSM, MAA, Director DTS, Director DTP, ISD)"
        Font = $BoxFont
        AutoSize = $true
    }
}
$SecurityNTKRadioButton = New-Object @objParams
#endregion Security NTK radiobutton

#region Senior Staff NTK radiobutton
$objParams = @{
    TypeName = 'System.Windows.Forms.RadioButton'
    Property = @{
        Name = "SeniorStaffNTKRadioButton"
        Text = "Senior Staff (CO, XO, Director NFAS, Director NPS, CMC)"
        Font = $BoxFont
        AutoSize = $true
    }
}
$SeniorStaffNTKRadioButton = New-Object @objParams
#endregion Senior Staff NTK radiobutton

#endregion NTK controls
#endregion configure individual controls

#region TableLayoutPanels
#region main table layout panel
$MainTableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$MainTableLayoutPanel.RowCount = 3 #how many rows
$MainTableLayoutPanel.ColumnCount = 6 #how many columns
$MainTableLayoutPanel.BorderStyle = "Fixed3D"
# $MainTableLayoutPanel.CellBorderStyle = "Inset"

$MainTableLayoutPanel.SetColumnSpan($DisplayTitleLabel,6)
$MainTableLayoutPanel.SetColumnSpan($DisplayInfoBox,6)
$MainTableLayoutPanel.SetColumnSpan($ADAccountClearExpiryButton,3)
$MainTableLayoutPanel.SetRowSpan($DisplayInfoBox,2)

$MainTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 30))) | Out-Null
$MainTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 8))) | Out-Null
$MainTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 62))) | Out-Null

$MainTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,5))) | Out-Null
$MainTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$MainTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,5))) | Out-Null
$MainTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,5))) | Out-Null
$MainTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$MainTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,45))) | Out-Null

# column 1
$MainTableLayoutPanel.Controls.Add($DisplayTitleLabel,0,1)
$MainTableLayoutPanel.Controls.Add($DisplayInfoBox,0,2)
# column 2
$MainTableLayoutPanel.Controls.Add($ADGroupsBox,1,2)
# column 3
$MainTableLayoutPanel.Controls.Add($RemoveGroupButton,2,2)
$MainTableLayoutPanel.Controls.Add($ADAccountClearExpiryButton,2,2)
# column 4
$MainTableLayoutPanel.Controls.Add($AddGroupButton,3,2)
# column 5
$MainTableLayoutPanel.Controls.Add($ADGroupMembershipBox,4,2)

$MainTableLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
#endregion main table

#region tablelayoutpanel2
$tableLayoutPanel2 = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel2.RowCount = 5
$tableLayoutPanel2.ColumnCount = 5
$tableLayoutPanel2.Anchor =[System.Windows.Forms.AnchorStyles]::Top `
    -bor [System.Windows.Forms.AnchorStyles]::Bottom `
    -bor [System.Windows.Forms.AnchorStyles]::Left `
    -bor [System.Windows.Forms.AnchorStyles]::Right
# $tableLayoutPanel2.CellBorderStyle = "Inset"

$tableLayoutPanel2.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel2.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel2.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel2.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel2.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null

$tableLayoutPanel2.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,15))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,25))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null

    # column 1
$tableLayoutPanel2.Controls.Add($ADUserLabel,0,0)
$tableLayoutPanel2.Controls.Add($ADPrincipalTextBox,0,1)
$tableLayoutPanel2.Controls.Add($ADLookupButton,0,2)
    #column 2
$tableLayoutPanel2.Controls.Add($ADSearchTypeLabel,1,0)
$tableLayoutPanel2.Controls.Add($ADSearchUsersRadioButton,1,1)
$tableLayoutPanel2.Controls.Add($ADSearchComputersRadioButton,1,2)
$tableLayoutPanel2.Controls.Add($ADSearchServiceAccountsRadioButton,1,3)
    #column 3
$tableLayoutPanel2.Controls.Add($ADAccountStatusLabel,2,0)
$tableLayoutPanel2.Controls.Add($ADAccountExpirationLabel,2,1)
$tableLayoutPanel2.Controls.Add($ADAccountEnableLabel,2,2)
$tableLayoutPanel2.Controls.Add($ADAccountUnlockLabel,2,3)
$tableLayoutPanel2.Controls.Add($ADAccountRequiresSmartcardLabel,2,4)
    #column 4
$tableLayoutPanel2.Controls.Add($ADAccountActionsLabel,3,0)
$tableLayoutPanel2.Controls.Add($ADAccountSetExpiryButton,3,1)
$tableLayoutPanel2.Controls.Add($ADAccountEnableButton,3,2)
$tableLayoutPanel2.Controls.Add($ADAccountUnlockUserAccountButton,3,3)
$tableLayoutPanel2.Controls.Add($ADAccountRequiresSmartcardCheckBox,3,4)
    #column 5
$tableLayoutPanel2.Controls.Add($ADAccountResetAccountPasswordButton,4,1)
$tableLayoutPanel2.Controls.Add($ADGetGroupMembershipButton,4,2)
$tableLayoutPanel2.Controls.Add($ValidateNPUserButton,4,3)

$tableLayoutPanel2.SetColumnSpan($ADAccountActionsLabel,2)
$tableLayoutPanel2.SetRowSpan($ADLookupButton,2)

$tableLayoutPanel2.Dock = [System.Windows.Forms.DockStyle]::Fill
#endregion tablelayoutpanel2

#region Account Expiration Panel
$ExpiryTableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$ExpiryTableLayoutPanel.RowCount = 3 #how many rows
$ExpiryTableLayoutPanel.ColumnCount = 1 #how many columns
$ExpiryTableLayoutPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
    -bor [System.Windows.Forms.AnchorStyles]::Bottom `
    -bor [System.Windows.Forms.AnchorStyles]::Left `
    -bor [System.Windows.Forms.AnchorStyles]::Right
# $ExpiryTableLayoutPanel.CellBorderStyle = "Inset" 

$ExpiryTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null
$ExpiryTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null
$ExpiryTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null

$ExpiryTableLayoutPanel.Controls.Add($ADAccountExpiryDatePicker,0,0)
$ExpiryTableLayoutPanel.Controls.Add($NewPasswordTextBox,0,0)
$ExpiryTableLayoutPanel.Controls.Add($UpdateExpiryButton,0,2)
$ExpiryTableLayoutPanel.Controls.Add($UpdatePasswordButton,0,2)

$ExpiryTableLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
#endregion account expiration panel

#region Reports Panel
$ADReportsTableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$ADReportsTableLayoutPanel.RowCount = 5 #how many rows
$ADReportsTableLayoutPanel.ColumnCount = 3 #how many columns
$ADReportsTableLayoutPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
    -bor [System.Windows.Forms.AnchorStyles]::Bottom `
    -bor [System.Windows.Forms.AnchorStyles]::Left `
    -bor [System.Windows.Forms.AnchorStyles]::Right
$ADReportsTableLayoutPanel.BorderStyle = "Fixed3d"
# $ADReportsTableLayoutPanel.CellBorderStyle = "Outset"
# $ADReportsTableLayoutPanel.CellBorderStyle = "Inset" 

$ADReportsTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33.3))) | Out-Null
$ADReportsTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33.3))) | Out-Null
$ADReportsTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33.3))) | Out-Null

$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null

# $ADReportsTableLayoutPanel.SetColumnSpan($ADReportsLabel,3)

$ADReportsTableLayoutPanel.Controls.Add($ADReportsLabel,1,0)
$ADReportsTableLayoutPanel.Controls.Add($ADReportsDomainControllersButton,0,1)
$ADReportsTableLayoutPanel.Controls.Add($ADReportsDisabledComputersButton,0,2)
$ADReportsTableLayoutPanel.Controls.Add($ADReportsInactiveComputersButton,0,3)
$ADReportsTableLayoutPanel.Controls.Add($ADReportsInactiveUsersButton,0,4)
$ADReportsTableLayoutPanel.Controls.Add($ADReportsLockedOutUsersButton,1,1)
$ADReportsTableLayoutPanel.Controls.Add($ADReportsUsersNeverLoggedOnButton,1,2)
$ADReportsTableLayoutPanel.Controls.Add($ADReportsUsersRecentlyCreatedButton,1,3)
$ADReportsTableLayoutPanel.Controls.Add($ADReportsUsersRecentlyDeletedButton,1,4)
$ADReportsTableLayoutPanel.Controls.Add($ADReportsUsersRecentlyModifiedButton,2,1)
$ADReportsTableLayoutPanel.Controls.Add($ADReportsUsersWithoutManagerButton,2,2)

$ADReportsTableLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
#endregion reports panel

#region Options Buttons Panel
$OptionButtonsTableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$OptionButtonsTableLayoutPanel.RowCount = 5
$OptionButtonsRowSpan = 5
$OptionButtonsTableLayoutPanel.ColumnCount = 3
$OptionButtonsTableLayoutPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
    -bor [System.Windows.Forms.AnchorStyles]::Bottom `
    -bor [System.Windows.Forms.AnchorStyles]::Left `
    -bor [System.Windows.Forms.AnchorStyles]::Right
# $OptionButtonsTableLayoutPanel.CellBorderStyle = "Inset"

$OptionButtonsTableLayoutPanel.SetColumnSpan($OptionButtonsLabel,3)

$OptionButtonsTableLayoutPanel.Controls.Add($OptionButtonsLabel,0,0)
$OptionButtonsTableLayoutPanel.Controls.Add($DisplayReportsPanelButton,0,1)

$OptionButtonsTableLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
#endregion option buttons panel

#region Domain Servers Panel
$DomainServersTableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$DomainServersTableLayoutPanel.RowCount = 1
$DomainServersTableLayoutPanel.ColumnCount = 6
$DomainServersTableLayoutPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
    -bor [System.Windows.Forms.AnchorStyles]::Bottom `
    -bor [System.Windows.Forms.AnchorStyles]::Left `
    -bor [System.Windows.Forms.AnchorStyles]::Right
# $DomainServersTableLayoutPanel.CellBorderStyle = "Outset"

if ($ini.Custom.ADServers) {
    $OptionButtonsRowSpan = 4
    $labelParams = @{
        TypeName = 'System.Windows.Forms.Label'
        Property = @{
            Text = 'Directory Servers:'
            Font = $BoldBoxFont
            AutoSize = $true
            Anchor = [System.Windows.Forms.AnchorStyles]::Top `
                -bor [System.Windows.Forms.AnchorStyles]::Bottom `
                -bor [System.Windows.Forms.AnchorStyles]::Left `
                -bor [System.Windows.Forms.AnchorStyles]::Right
        }
    }
    $DomainServersTableLayoutPanel.Controls.Add((New-Object @labelParams),0,0)
    $i=1
    $ini.Custom.ADServers.split(',') | Foreach-Object {
        $domain = $PSItem
        $objParams = @{
            TypeName = 'System.Windows.Forms.RadioButton'
            Property = @{
                Name = $domain
                Text = $domain
                Font = $BoxFont
                AutoSize = $true
                # Checked = $PSItem -eq $env:USERDNSDOMAIN
                Anchor = [System.Windows.Forms.AnchorStyles]::Top `
                    -bor [System.Windows.Forms.AnchorStyles]::Bottom `
                    -bor [System.Windows.Forms.AnchorStyles]::Left `
                    -bor [System.Windows.Forms.AnchorStyles]::Right
            }
        }
        $DomainServersTableLayoutPanel.Controls.Add((New-Object @objParams),$i,0)
        $DomainServersTableLayoutPanel.Controls.Item($PSItem).add_Click({ 
            Write-Host "Set Domain Server to $domain"
            $script:server = $domain 
        })
        if ($PSItem -eq $env:USERDNSDOMAIN) {
            $DomainServersTableLayoutPanel.Controls.Item($PSItem).PerformClick()
        }
        $i++
    }
}

$DomainServersTableLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
#endregion domain servers panel

#region Group controls Panel
$GroupControlsTableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$GroupControlsTableLayoutPanel.RowCount = 7
$GroupControlsTableLayoutPanel.ColumnCount = 3
$GroupControlsTableLayoutPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
    -bor [System.Windows.Forms.AnchorStyles]::Bottom `
    -bor [System.Windows.Forms.AnchorStyles]::Left `
    -bor [System.Windows.Forms.AnchorStyles]::Right
$GroupControlsTableLayoutPanel.BorderStyle = "None"
# $GroupControlsTableLayoutPanel.CellBorderStyle = "Inset"

$GroupControlsTableLayoutPanel.Controls.Add($UpdateGroupMembershipsButton,0,1)
$GroupControlsTableLayoutPanel.Controls.Add($NTKLabel,2,0)
$GroupControlsTableLayoutPanel.Controls.Add($NoNTKRadioButton,2,1)
$GroupControlsTableLayoutPanel.Controls.Add($NonNuclearNTKRadioButton,2,2)
$GroupControlsTableLayoutPanel.Controls.Add($NuclearNTKRadioButton,2,3)
$GroupControlsTableLayoutPanel.Controls.Add($IsdNTKRadioButton,2,4)
$GroupControlsTableLayoutPanel.Controls.Add($SecurityNTKRadioButton,2,5)
$GroupControlsTableLayoutPanel.Controls.Add($SeniorStaffNTKRadioButton,2,6)

$GroupControlsTableLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
#endregion group controls panel

$MainTableLayoutPanel.Controls.Add($tableLayoutPanel2,0,0)
$MainTableLayoutPanel.Controls.Add($ExpiryTableLayoutPanel,1,2)
$MainTableLayoutPanel.Controls.Add($GroupControlsTableLayoutPanel,5,2)
$tableLayoutPanel2.Controls.Add($ADReportsTableLayoutPanel,2,0)
$tableLayoutPanel2.Controls.Add($OptionButtonsTableLayoutPanel,2,0)
$tableLayoutPanel2.Controls.Add($DomainServersTableLayoutPanel,0,4)

$MainTableLayoutPanel.SetColumnSpan($tableLayoutPanel2,6)
$tableLayoutPanel2.SetColumnSpan($ADReportsTableLayoutPanel,3)
$tableLayoutPanel2.SetColumnSpan($OptionButtonsTableLayoutPanel,3)
$tableLayoutPanel2.SetColumnSpan($DomainServersTableLayoutPanel,6)
$tableLayoutPanel2.SetRowSpan($ADReportsTableLayoutPanel,5)
$tableLayoutPanel2.SetRowSpan($OptionButtonsTableLayoutPanel,$OptionButtonsRowSpan)
#endregion tablelayoutpanels
#endregion 

# size the form depending on the display size
$screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = $screen.Width * .75
$System_Drawing_Size.Height = $screen.Height * .75

# create the form object
$objParams = @{
    TypeName = 'System.Windows.Forms.Form'
    Property = @{
        Name = "form"
        Text = "Account Viewer and Updater"
        FormBorderStyle = "FixedDialog"
        StartPosition = "CenterScreen"
        ClientSize = $System_Drawing_Size
        # AutoScaleDimensions =  New-Object System.Drawing.SizeF(96, 96)
        # AutoScaleMode  = [System.Windows.Forms.AutoScaleMode]::Dpi
        # AutoScale = $true
    }
}
$form = New-Object @objParams
$form.Add_FormClosed({handler_formclose})
$form.SuspendLayout()

$form.DataBindings.DefaultDataSourceUpdateMode = 0
$form.Controls.AddRange(@($MainTableLayoutPanel))
# set control visibility on form load
Reset-Form
$form.ResumeLayout()

#Show the Form
Write-Log -Message "$env:USERNAME started a new session." -Severity Information 
$form.ShowDialog()