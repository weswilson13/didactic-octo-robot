function handler_ADLookupButton_Click {
    $adParams = @{}
    if ($script:server) { $adParams["Server"] = $script:server }
    
    # reset the form
    Reset-Form -ExceptPrincipal

    try {
        $principal = $ADPrincipalTextBox.Text
        Write-Host "Looking up user $principal"
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
            $ADAccountEnableButton.Enabled = $objPrincipal.ObjectClass -in @('user','msDS-GroupManagedServiceAccount')
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
            $ADAccountRequiresSmartcardCheckBox.Enabled = $objPrincipal.ObjectClass -eq 'user'
            $ADAccountUnlockLabel.Text = "Account Locked Out: $($objPrincipal.LockedOut)"

            $ADGetGroupMembershipButton.Visible=$true
            $ADAccountActionsLabel.Visible = $true

            $ADAccountExpiryDatePicker.Value = switch($objPrincipal.AccountExpirationDate) {
                $null { $ADAccountExpiryDatePicker.MaxDate }
                default { $PSItem }
            }
            $ADAccountStatusLabel.Visible = $true
            $ADAccountEnableLabel.Visible = $true
            $ADAccountUnlockLabel.Visible = $true
            $ADAccountEnableButton.Visible = $true
            $ADAccountSetExpiryButton.Visible = $true
            $ADAccountExpirationLabel.Visible = $true
            $ADAccountSetExpiryButton.Enabled = $objPrincipal.ObjectClass -in @('user','msDS-GroupManagedServiceAccount')
            $ADAccountUnlockUserAccountButton.Visible = $true
            $ADAccountUnlockUserAccountButton.Enabled = $objPrincipal.LockedOut
            $ADUpdateUserInformationButton.Visible = $true
            $ADUpdateUserInformationButton.Enabled = $objPrincipal.ObjectClass -eq 'user'
            $ADAccountResetAccountPasswordButton.Visible = $true
            $ADAccountResetAccountPasswordButton.Enabled = $objPrincipal.ObjectClass -eq 'user'
            $ValidateNPUserButton.Visible = $true
            $ValidateNPUserButton.Enabled = $objPrincipal.ObjectClass -eq 'user'
            $ADAccountRequiresSmartcardLabel.Visible = $true
            $ADAccountRequiresSmartcardCheckBox.Visible = $true
            
            Write-Log -Message "$env:USERNAME retrieved account properties for account $($objPrincipal.SamAccountName)" -Severity Information
        }
    }
    catch {
        $errorMessage = @{
            ErrorMessage = "Unable to find $principal. Check session logs for additional details."
            MessageTitle = "Active Directory Search Failed"
        }
        New-ErrorMessage @errorMessage
    } 
  }
function handler_ADSearchComputersRadioButton_Click {   
    Write-Host "Computers Radio Button Pressed"
    Reset-Form
    $ADUserLabel.Text = "Enter a Computer"
    $ADLookupButton.Text = "Lookup Computer"
}
function handler_ADSearchUsersRadioButton_Click {
    Write-Host "Users Radio Button Pressed"
    Reset-Form
    $ADUserLabel.Text = "Enter a Username"
    $ADLookupButton.Text = "Lookup User"
}
function handler_ADSearchServiceAccountsRadioButton_Click {
    Write-Host "ServiceAccounts Radio Button Pressed"
    Reset-Form
    $ADUserLabel.Text = "Enter a sMSA/gMSA"
    $ADLookupButton.Text = "Lookup Service Account"
}
function handler_ADGetGroupMembershipButton_Click {
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
            $UpdateGroupMembershipsButton.Visible = $true
            $UpdateGroupMembershipsButton.Enabled = $false
            $NTKAssignmentButton.Enabled = $objPrincipal.ObjectClass -eq 'User'
            Reset-GroupLists
            Write-Log -Message "$env:USERNAME enumerated group membership for account $($objPrincipal.SamAccountName)" -Severity Information
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
    }
}
function handler_AddGroupButton_Click {
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

        $UpdateGroupMembershipsButton.Enabled = $true 
    }
}
function handler_RemoveGroupButton_Click {
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

        $UpdateGroupMembershipsButton.Enabled = $true 
    }
}
function handler_UpdateGroupMembershipButton_Click {
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
        $errorMessage = @{
            ErrorMessage = "Failed to update group memberships. Check session logs for additional details."
            MessageTitle = "Group Membership Update Failed"
        }
        New-ErrorMessage @errorMessage
    }
}
function handler_ADAccountEnableButton_Click {
    try {
        # Set-ADUser $objPrincipal -Enabled (!$objPrincipal.Enabled) -Confirm:$false
        $action = switch ($objPrincipal.Enabled) {
            $true { "Disable" }
            $false { "Enable" }
        }

        $message = "Are you sure you want to $($action.ToLower()) $($objPrincipal.SamAccountName)?"
        $ans = [System.Windows.MessageBox]::Show($message, "Verify Action",`
            [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
        if ($ans -eq "Yes") {
            Invoke-Expression "$action-ADAccount `$objPrincipal -Confirm:`$false"

            $script:objPrincipal = Get-ADUser $objPrincipal -Properties *
            $this.Text = switch($objPrincipal.Enabled) {
                $true { "Disable Account";break }
                $false { "Enable Account";break }
            }
            Write-Host $this.Text
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
        $errorMessage = @{
            ErrorMessage = "Unable to update account. Check session logs for additional details."
            MessageTitle = "Account Enable/Disable Failed"
        }
        New-ErrorMessage @errorMessage
    }
}
function handler_ADAccountRequiresSmartCardCheckbox_Click {
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
        
                Write-Log -Message "$env:USERNAME $state SmartcardLogonRequired for user $($objPrincipal.SamAccountName)" -Severity Information
        }
        if ($ans -eq "No") {
            $ADAccountRequiresSmartcardCheckBox.Checked = $false
        }
    }
    catch {
        $errorMessage = @{
            ErrorMessage = "Unable to $currentState account. Check session logs for additional details."
            MessageTitle = "SmartcardLogonRequired Enable/Disable Failed"
        }
        New-ErrorMessage @errorMessage
    }
}
function handler_ADAccountExpiryButton_Click {
    Clear-Console
    $DisplayInfoBox.Visible = $false
    $DisplayTitleLabel.Text = "Modify Account Expiration Date"
    $ExpiryTableLayoutPanel.Visible = $true
    $ADAccountExpiryDatePicker.Visible = $true
    $ADAccountClearExpiryButton.Visible = $true
    $ADAccountClearExpiryButton.Enabled = $null -ne $objPrincipal.AccountExpirationDate
    $UpdateExpiryButton.Visible = $true
}
function handler_ADAccountClearExpiryButton_Click {
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
        $errorMessage = @{
            ErrorMessage = "Unable to clear account expiration. Check session logs for additional details."
            MessageTitle = "Expiry update Failed"
        }
        New-ErrorMessage @errorMessage
    }
}
function handler_UpdateExpiryButton_Click {
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
        $errorMessage = @{
            ErrorMessage = "Unable to update account expiration. Check session logs for additional details."
            MessageTitle = "Account update Failed"
        }
        New-ErrorMessage @errorMessage
    }
}
 #region Reports Error Handlers
function handler_ADReportsDisabledComputersButton_Click {
        Write-Host "Get DisabledComputers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Disabled Computers"
        $DisplayInfoBox.Text = (Get-DisabledComputers | Format-Table -AutoSize | Out-String)
}
function handler_ADReportsDomainControllersButton_Click {
        Write-Host "Get DomainControllers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Domain Controllers"
        $DisplayInfoBox.Text = (Get-DomainControllers | Format-Table -AutoSize | Out-String)
}
function handler_ADReportsInactiveComputersButton_Click {
        Write-Host "Get InactiveComputers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Inactive Computers"
        $DisplayInfoBox.Text = (Get-InactiveComputers | Format-Table -AutoSize | Out-String)
}
function handler_ADReportsInactiveUsersButton_Click {
        Write-Host "Get InactiveUsers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Inactive Users"
        # $user = Get-InactiveUsers | Out-GridView -Title 'Inactive Users' -PassThru
        # $ADPrincipalTextBox.Text = $user.SamAccountName
        Get-InactiveUsers
        $DisplayInfoBox.Text = (Import-Csv $env:TEMP\InactiveUsers.csv) | Out-String
}
function handler_ADReportsLockedOutUsersButton_Click {
        Write-Host "Get LockedOutUsers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Locked Out Users"
        $DisplayInfoBox.Text = (Get-LockedOutUsers | Format-Table -AutoSize | Out-String)
}
function handler_ADReportsUsersNeverLoggedOnButton_Click {
        Write-Host "Get UsersNeverLoggedOn Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Never Logged On"
        $DisplayInfoBox.Text = (Get-UsersNeverLoggedOn | Format-Table -AutoSize | Out-String)
}
function handler_ADReportsUsersRecentlyCreatedButton_Click {
        Write-Host "Get UsersRecentlyCreated Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Recently Created"
        $DisplayInfoBox.Text = (Get-UsersRecentlyCreated | Format-Table -AutoSize | Out-String)
}
function handler_ADReportsUsersRecentlyDeletedButton_Click {
        Write-Host "Get UsersRecentlyDeleted Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Recently Deleted"
        $DisplayInfoBox.Text = (Get-UsersRecentlyDeleted | Format-Table -AutoSize | Out-String)
}
function handler_ADReportsUsersRecentlyModifiedButton_Click {
        Write-Host "Get Users Recently Modified Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Recently Modified"
        $DisplayInfoBox.Text = (Get-UsersRecentlyModified | Format-Table -AutoSize | Out-String)
}
function handler_ADReportsUsersWithoutManagerButton_Click {
        Write-Host "Get Users Without Manager Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Without Manager"
        $DisplayInfoBox.Text = (Get-UsersWithoutManager | Format-Table -AutoSize | Out-String)
}
#endregion
function handler_ADAccountUnlockUserAccountButton_Click {
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
function handler_ADAccountResetAccountPasswordButton_Click {
    Write-Host "Reset account password button clicked"
    Clear-Console
    Clear-Console
    $DisplayInfoBox.Visible = $false
    $DisplayTitleLabel.Text = "Reset Account Password"
    $ExpiryTableLayoutPanel.Visible = $true
    $NewPasswordTextBox.Visible = $true
    $UpdatePasswordButton.Visible = $true
}
function handler_UpdatePasswordButton_Click {
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
        $errorMessage = @{
            ErrorMessage = "Unable to reset password. Check session logs for additional details."
            MessageTitle = "Password Reset Failed"
        }
        New-ErrorMessage @errorMessage
    }
}
function handler_DisplayReportsPanelButton_Click {
    $OptionButtonsTableLayoutPanel.Visible = $false
    $ADReportsTableLayoutPanel.Visible = $true
}
function handler_ValidateNPUserButton_Click {
    try {
        Write-Host "Validate Notepad User"
        $ans = [System.Windows.MessageBox]::Show("Validate $($objPrincipal.SamAccountName) against NOTEPAD?", "Verify Action",`
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($ans -eq "Yes") {
            $connectionParams = Get-ConnectionParameters -IniSection NotepadDbConfig -Cmdlet InvokeSqlCmd

            $sqlParameters = @{
                ServerInstance = $connectionParams.ServerInstance
                Database = $connectionParams.Database
                Encrypt = $connectionParams.Encrypt
                TrustServerCertificate = $connectionParams.TrustServerCertificate
                ApplicationName = $form.Name
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

            $logMessage = "$env:USERNAME validated user $($objPrincipal.SamAccountName) against NOTEPAD database.`n"
            $logMessage += "Updated WinLogonID to $($objPrincipal.UserPrincipalName) for the PID $($_PID.PID)."
            
            [System.Windows.MessageBox]::Show($logMessage, "NP User Validation",`
                        [System.Windows.MessageBoxButton]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

            Write-Log -Message $logMessage -Severity Information
        }
    }
    catch {
        $errorMessage = @{
            ErrorMessage = "Unable to validate user against NOTEPAD. Check session logs for additional details."
            MessageTitle = "NOTEPAD Validation Failed"
        }
        New-ErrorMessage @errorMessage
    }
}
function handler_NTKAssignmentButton_Click {
    $NTKAssignmentPanel.Visible = $true
}

function handler_NTKRadioButton_Click {
    Param(
        # NTK Group
        [Parameter(Mandatory=$false)]
        [ValidateSet('None','NonNuclearTrained','NuclearTrained','InformationSecurityDepartment','PhysicalSecurity','SeniorStaff')]
        [string]$NTKAssignment = 'None'
    )

    try {   
        Write-Host "$NTKAssignment NTK Selected"
        $ans = [System.Windows.MessageBox]::Show("Assign $NTKAssignment NTKs to $($objPrincipal.SamAccountName)?", "Verify Action",`
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($ans -eq "Yes") {
            Remove-NTKGroups -ADUser $objPrincipal
            Set-NTKGroups -ADUser $objPrincipal -NTKAssignment $NTKAssignment

            # update the AD User object
            $script:objPrincipal = Get-ADUser $objPrincipal -Properties *

            $logMessage = @{
                Message = "$env:USERNAME reset NTK Groups to '$NTKAssignment' for user $($objPrincipal.SamAccountName)"
                Severity = 'Information'
            }
            $message = "$($LogMessage.Message). Please allow ~10 seconds for Active Directory to reflect the changes."
            [System.Windows.MessageBox]::Show($message, "NTK Group Assignment Success",`
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Write-Log @logMessage
        }
    }
    catch {
        $errorMessage = @{
            ErrorMessage = "Failed to Set NTK Group. Check session logs for additional details."
            MessageTitle = "NTK Group Assignment Failed"
        }
        New-ErrorMessage @errorMessage
    }
}
function handler_ADUpdateUserInformationButton_Click {

    Write-Host "Modify User Information Button Clicked"
    
    Clear-Console
    $DisplayTitleLabel.Text = "Modify User Information"
    $DisplayInfoBox.Visible = $false
    $ADUpdateUserInformationPanel.Visible = $true

    $ADMapping = Get-UserMapping
    $ADUserFirstNameTextBox.Text = $objPrincipal.GivenName
    $ADUserLastNameTextBox.Text = $objPrincipal.Surname
    $ADUserRateTextBox.Text = $objPrincipal.$($ADMapping.Rate)
    $ADUserOfficeTextBox.Text = $objPrincipal.Office
    $ADUserTelephoneNumberTextBox.Text = $objPrincipal.OfficePhone
    $ADUserPRDTextBox.Value = $objPrincipal.$($ADMapping.PRD)
    $ADUserDescriptionTextBox.Multiline = $true
    $ADUserDescriptionTextBox.Text = $objPrincipal.Description
}
function handler_SetUserInfoButton_Click {
    function Set-Attribute {
        param(
            [string]$Value,
            [string]$Attribute
        )

        if ($Value) { $adParams["$Attribute"] = $Value}
        else { $attributesToClear.Add($Attribute) }        
    }

    try {
        Write-Host "Update User Info Panel Button Clicked"
        $ans = [System.Windows.MessageBox]::Show("Update AD attributes for user $($objPrincipal.SamAccountName)?", "Verify Action",`
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($ans -eq "Yes") {
            $ADMapping = Get-UserMapping
            $adParams = @{}
            [System.Collections.ArrayList]$attributesToClear = @()
            
            Set-Attribute -Value $ADUserFirstNameTextBox.Text -Attribute GivenName
            Set-Attribute -Value $ADUserLastNameTextBox.Text -Attribute Surname
            Set-Attribute -Value $ADUserRateTextBox.Text -Attribute $($ADMapping.Rate)
            Set-Attribute -Value $ADUserOfficeTextBox.Text -Attribute Office
            Set-Attribute -Value $ADUserTelephoneNumberTextBox.Text -Attribute OfficePhone
            Set-Attribute -Value $ADUserDescriptionTextBox.Text -Attribute Description
            Set-Attribute -Value $ADUserPRDTextBox.Text -Attribute $($ADMapping.PRD)
            
            if ($attributesToClear) { $adParams["Clear"] = $attributesToClear -join ','}
            
            $objPrincipal | Set-AdUser @adParams -Confirm:$false
            $script:objPrincipal = Get-ADUser $objPrincipal -Properties *

            $message = "$env:USERNAME updated AD attributes for user $($objPrincipal.SamAccountName):`n$($adParams | Out-String)"
            Write-Log -Message $message -Severity Information

            [System.Windows.MessageBox]::Show($message, "Active Directory Update Success",`
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }
    catch {
        $errorMessage = @{
            ErrorMessage = "Failed to set AD attributes. Check session logs for additional details."
            MessageTitle = "Active Directory Update Failed"
        }
        New-ErrorMessage @errorMessage
    }
}
function handler_formclose {
    1..3 | ForEach-Object {[GC]::Collect()}
    
    Write-Log -Message "$env:USERNAME ended the session." -Severity Information 
    
    $form.Dispose()

    Import-SessionLog
    [Microsoft.Data.SqlClient.SqlConnection]::ClearAllPools()
}