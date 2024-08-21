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
    $tableLayoutPanel3.Visible = $false
}
function Clear-ReportPanel {
    # $ADReportsLabel.Visible = $false
    # $ADReportsDisabledComputersButton.Visible = $false
    # $ADReportsDomainControllersButton.Visible = $false
    # $ADReportsInactiveComputersButton.Visible = $false
    # $ADReportsInactiveUsersButton.Visible = $false
    # $ADReportsLockedOutUsersButton.Visible = $false
    # $ADReportsUsersNeverLoggedOnButton.Visible = $false
    # $ADReportsUsersRecentlyCreatedButton.Visible = $false
    # $ADReportsUsersRecentlyDeletedButton.Visible = $false
    # $ADReportsUsersRecentlyModifiedButton.Visible = $false
    # $ADReportsUsersWithoutManagerButton.Visible = $false
    $tableLayoutPanel4.Visible = $false    
}
function Reset-Form {
    param(
        [switch]$ExceptPrincipal
    )
    $Script:ADAccountExpiryDatePickerClicked = $false

    if (!$ExceptPrincipal.IsPresent) { $ADPrincipalTextBox.ResetText() }
    $ADGetGroupMembershipButton.Visible = $false
    $UpdateGroupMembershipsButton.Visible = $false
    $ADAccountStatusLabel.Visible = $false
    $ADAccountExpirationLabel.Visible = $false
    $ADAccountEnableLabel.Visible = $false
    $ADAccountUnlockLabel.Visible = $false
    $ADAccountEnableButton.Visible = $false
    $ADAccountRequiresSmartcardLabel.Visible = $false
    $ADAccountRequiresSmartcardCheckBox.Visible = $false
    $ADAccountActionsLabel.Visible = $false
    $ADAccountSetExpiryButton.Visible = $false
    # $ADReportsLabel.Visible = $true
    # $ADReportsDisabledComputersButton.Visible = $true
    # $ADReportsDomainControllersButton.Visible = $true
    # $ADReportsInactiveComputersButton.Visible = $true
    # $ADReportsInactiveUsersButton.Visible = $true
    # $ADReportsLockedOutUsersButton.Visible = $true
    # $ADReportsUsersNeverLoggedOnButton.Visible = $true
    # $ADReportsUsersRecentlyCreatedButton.Visible = $true
    # $ADReportsUsersRecentlyDeletedButton.Visible = $true
    # $ADReportsUsersRecentlyModifiedButton.Visible = $true
    # $ADReportsUsersWithoutManagerButton.Visible = $true
    $tableLayoutPanel4.Visible = $true

    Clear-Console
}

#dot sourced functions
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

Import-Module ActiveDirectory

#region font objects
$TitleFont = New-Object System.Drawing.Font("Calibri",24,[Drawing.FontStyle]::Bold)
# $BodyFont = New-Object System.Drawing.Font("Calibri",18,[Drawing.FontStyle]::Bold)
$BoxFont = New-Object System.Drawing.Font("Calibri", 12, [Drawing.FontStyle]::Regular)
$BoldBoxFont = New-Object System.Drawing.Font("Calibri", 12, [Drawing.FontStyle]::Bold)
$ConsoleFont = New-Object System.Drawing.Font("Lucida Console", 10, [Drawing.FontStyle]::Regular)
#endregion

#region create the controls
# Labels
$ADUserLabel = New-Object System.Windows.Forms.Label
$ADSearchTypeLabel = New-Object System.Windows.Forms.Label
$ADAccountStatusLabel = New-Object System.Windows.Forms.Label
$ADAccountExpirationLabel = New-Object System.Windows.Forms.Label
$ADAccountEnableLabel = New-Object System.Windows.Forms.Label
$ADAccountUnlockLabel = New-Object System.Windows.Forms.Label
$ADAccountRequiresSmartcardLabel = New-Object System.Windows.Forms.Label
$ADAccountActionsLabel = New-Object System.Windows.Forms.Label
$DisplayTitleLabel = New-Object System.Windows.Forms.Label
$ADReportsLabel = New-Object System.Windows.Forms.Label

# Text boxes
$ADPrincipalTextBox = New-Object System.Windows.Forms.TextBox

# RichTextBoxes
$DisplayInfoBox = New-Object System.Windows.Forms.RichTextBox

# Buttons
$ADLookupButton = New-Object System.Windows.Forms.Button
$ADGetGroupMembershipButton = New-Object System.Windows.Forms.Button
$AddGroupButton = New-Object System.Windows.Forms.Button
$RemoveGroupButton = New-Object System.Windows.Forms.Button
$UpdateGroupMembershipsButton = New-Object System.Windows.Forms.Button
$ADAccountEnableButton = New-Object System.Windows.Forms.Button
$ADAccountSetExpiryButton = New-Object System.Windows.Forms.Button
$UpdateExpiryButton = New-Object System.Windows.Forms.Button
$ADReportsDisabledComputersButton = New-Object System.Windows.Forms.Button
$ADReportsDomainControllersButton = New-Object System.Windows.Forms.Button
$ADReportsInactiveComputersButton = New-Object System.Windows.Forms.Button
$ADReportsInactiveUsersButton = New-Object System.Windows.Forms.Button
$ADReportsLockedOutUsersButton = New-Object System.Windows.Forms.Button
$ADReportsUsersNeverLoggedOnButton = New-Object System.Windows.Forms.Button
$ADReportsUsersRecentlyCreatedButton = New-Object System.Windows.Forms.Button
$ADReportsUsersRecentlyDeletedButton = New-Object System.Windows.Forms.Button
$ADReportsUsersRecentlyModifiedButton = New-Object System.Windows.Forms.Button
$ADReportsUsersWithoutManagerButton = New-Object System.Windows.Forms.Button
$ADAccountClearExpiryButton = New-Object System.Windows.Forms.Button

# ListBoxes
$ADGroupsBox = New-Object System.Windows.Forms.ListBox
$ADGroupMembershipBox = New-Object System.Windows.Forms.ListBox

# Datepicker
$ADAccountExpiryDatePicker = New-Object System.Windows.Forms.DateTimePicker

# RadioButtons
$ADSearchUsersRadioButton = New-Object System.Windows.Forms.RadioButton
$ADSearchComputersRadioButton = New-Object System.Windows.Forms.RadioButton
$ADSearchServiceAccountsRadioButton = New-Object System.Windows.Forms.RadioButton

# Checkboxes
$ADAccountRequiresSmartcardCheckBox = New-Object System.Windows.Forms.CheckBox
# $ADAccountExpiryCheckbox = New-Object System.Windows.Forms.CheckBox

# TableLayoutPanel
$tableLayoutPanel1 = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel1.RowCount = 3 #how many rows
$tableLayoutPanel1.ColumnCount = 6 #how many columns
# $tableLayoutPanel1.CellBorderStyle = "Inset"

$tableLayoutPanel1.SetColumnSpan($DisplayTitleLabel,6)
$tableLayoutPanel1.SetColumnSpan($DisplayInfoBox,6)
$tableLayoutPanel1.SetColumnSpan($ADAccountClearExpiryButton,3)
$tableLayoutPanel1.SetRowSpan($DisplayInfoBox,2)

$tableLayoutPanel1.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 30))) | Out-Null
$tableLayoutPanel1.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 8))) | Out-Null
$tableLayoutPanel1.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 62))) | Out-Null

$tableLayoutPanel1.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,5))) | Out-Null
$tableLayoutPanel1.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$tableLayoutPanel1.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,5))) | Out-Null
$tableLayoutPanel1.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,5))) | Out-Null
$tableLayoutPanel1.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$tableLayoutPanel1.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,45))) | Out-Null

# column 1
$tableLayoutPanel1.Controls.Add($DisplayTitleLabel,0,1)
$tableLayoutPanel1.Controls.Add($DisplayInfoBox,0,2)
# column 2
$tableLayoutPanel1.Controls.Add($ADGroupsBox,1,2)
# column 3
$tableLayoutPanel1.Controls.Add($RemoveGroupButton,2,2)
$tableLayoutPanel1.Controls.Add($ADAccountClearExpiryButton,2,2)
# column 4
$tableLayoutPanel1.Controls.Add($AddGroupButton,3,2)
# column 5
$tableLayoutPanel1.Controls.Add($ADGroupMembershipBox,4,2)

$tableLayoutPanel1.Dock = [System.Windows.Forms.DockStyle]::Fill

$tableLayoutPanel2 = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel2.RowCount = 5
$tableLayoutPanel2.ColumnCount = 4
# $tableLayoutPanel2.CellBorderStyle = "Inset"

$tableLayoutPanel2.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel2.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel2.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel2.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel2.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null

$tableLayoutPanel2.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,35))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,25))) | Out-Null

    # column 1
$tableLayoutPanel2.Controls.Add($ADUserLabel,0,0)
$tableLayoutPanel2.Controls.Add($ADPrincipalTextBox,0,1)
$tableLayoutPanel2.Controls.Add($ADLookupButton,0,3)
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
$tableLayoutPanel2.Controls.Add($ADAccountRequiresSmartcardCheckBox,3,3)
$tableLayoutPanel2.Controls.Add($ADGetGroupMembershipButton,3,4)
$tableLayoutPanel2.Controls.Add($UpdateGroupMembershipsButton,3,4)

$tableLayoutPanel2.Dock = [System.Windows.Forms.DockStyle]::Fill

$tableLayoutPanel3 = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel3.RowCount = 3 #how many rows
$tableLayoutPanel3.ColumnCount = 1 #how many columns
# $tableLayoutPanel3.CellBorderStyle = "Inset" 

$tableLayoutPanel3.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null
$tableLayoutPanel3.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null
$tableLayoutPanel3.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null

$tableLayoutPanel3.Controls.Add($ADAccountExpiryDatePicker,0,0)
$tableLayoutPanel3.Controls.Add($UpdateExpiryButton,0,2)

$tableLayoutPanel3.Dock = [System.Windows.Forms.DockStyle]::Fill

$tableLayoutPanel4 = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel4.RowCount = 5 #how many rows
$tableLayoutPanel4.ColumnCount = 3 #how many columns
$tableLayoutPanel4.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
-bor [System.Windows.Forms.AnchorStyles]::Bottom `
-bor [System.Windows.Forms.AnchorStyles]::Left `
-bor [System.Windows.Forms.AnchorStyles]::Right
# $tableLayoutPanel4.CellBorderStyle = "Inset" 

$tableLayoutPanel4.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel4.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel4.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel4.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel4.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null

$tableLayoutPanel4.SetColumnSpan($ADReportsLabel,3)

$tableLayoutPanel4.Controls.Add($ADReportsLabel,0,0)
$tableLayoutPanel4.Controls.Add($ADReportsDomainControllersButton,0,1)
$tableLayoutPanel4.Controls.Add($ADReportsDisabledComputersButton,0,2)
$tableLayoutPanel4.Controls.Add($ADReportsInactiveComputersButton,0,3)
$tableLayoutPanel4.Controls.Add($ADReportsInactiveUsersButton,0,4)
$tableLayoutPanel4.Controls.Add($ADReportsLockedOutUsersButton,1,1)
$tableLayoutPanel4.Controls.Add($ADReportsUsersNeverLoggedOnButton,1,2)
$tableLayoutPanel4.Controls.Add($ADReportsUsersRecentlyCreatedButton,1,3)
$tableLayoutPanel4.Controls.Add($ADReportsUsersRecentlyDeletedButton,1,4)
$tableLayoutPanel4.Controls.Add($ADReportsUsersRecentlyModifiedButton,2,1)
$tableLayoutPanel4.Controls.Add($ADReportsUsersWithoutManagerButton,2,2)

$tableLayoutPanel4.Dock = [System.Windows.Forms.DockStyle]::Fill

$tableLayoutPanel1.Controls.Add($tableLayoutPanel2,0,0)
$tableLayoutPanel1.Controls.Add($tableLayoutPanel3,1,2)
$tableLayoutPanel2.Controls.Add($tableLayoutPanel4,2,0)

$tableLayoutPanel1.SetColumnSpan($tableLayoutPanel2,6)
$tableLayoutPanel2.SetColumnSpan($tableLayoutPanel4,2)
$tableLayoutPanel2.SetRowSpan($tableLayoutPanel4,5)
#endregion

#region event handlers
$handler_ADLookupButton_Click = 
  {
    # reset the form
    Reset-Form -ExceptPrincipal

    try {
        $principal = $ADPrincipalTextBox.Text
        if ($principal) {
            Clear-ReportPanel 
            $Script:objPrincipal = switch ($true) {
                $ADSearchUsersRadioButton.Checked { Get-ADUser -Identity $principal -Properties *; break } 
                $ADSearchComputersRadioButton.Checked { Get-ADComputer -Identity $principal -Properties *; break }
                $ADSearchServiceAccountsRadioButton.Checked { Get-ADServiceAccount -Identity $principal -Properties *;break }
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
                default { $PSItem }
            }
            $ADAccountExpirationLabel.Text = "Account Expiration Date: $strExpiry"
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
                # $ADAccountExpiryDatePicker.Visible = $true
                if ($objPrincipal.ObjectClass -eq 'user') {
                    $ADAccountRequiresSmartcardLabel.Visible = $true
                    $ADAccountRequiresSmartcardCheckBox.Visible = $true
                }
            }
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        [System.Windows.MessageBox]::Show("Unable to find $principal", "Active Directory Search Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } 
  }

$handler_ADSearchComputersRadioButton_Click = 
{   
    Write-Host "Computers Radio Button Pressed"
    Reset-Form
    $ADUserLabel.Text = "Enter a computer name"
    $ADLookupButton.Text = "Lookup Computer"
}

$handler_ADSearchUsersRadioButton_Click = 
{
    Write-Host "Users Radio Button Pressed"
    Reset-Form
    $ADUserLabel.Text = "Enter a username"
    $ADLookupButton.Text = "Lookup User"
}

$handler_ADSearchServiceAccountsRadioButton_Click = 
{
    Write-Host "ServiceAccounts Radio Button Pressed"
    Reset-Form
    $ADUserLabel.Text = "Enter a sMSA/gMSA"
    $ADLookupButton.Text = "Lookup Service Account"
}

$handler_ADGetGroupMembershipButton_Click =
{
    Write-Host "Get Group Memberships"
    Clear-Console
    if ($objPrincipal) {
        $DisplayInfoBox.Visible=$false
        $DisplayTitleLabel.Text = "Group Membership"
        $ADGroupsBox.Visible = $true
        $RemoveGroupButton.Visible = $true
        $AddGroupButton.Visible = $true
        $ADGroupMembershipBox.Visible = $true
        Get-ADGroup -Filter 'GroupScope -ne "DomainLocal" -and Name -ne "Domain Users"' | 
        Where-Object { $_.DistinguishedName -notin $objPrincipal.MemberOf } | 
        ForEach-Object {
            $ADGroupsBox.Items.Add($PSItem.Name)
        }
        $objPrincipal.MemberOf.ForEach({$ADGroupMembershipBox.Items.Add((Get-ADGroup $PSItem).SamAccountName)})
    }
    
}

$handler_AddGroupButton_Click = 
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

        $ADGetGroupMembershipButton.Visible = $false
        $UpdateGroupMembershipsButton.Visible = $true 
    }
}

$handler_RemoveGroupButton_Click = 
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

        $ADGetGroupMembershipButton.Visible = $false
        $UpdateGroupMembershipsButton.Visible = $true 
    }
}

$handler_UpdateGroupMembershipButton_Click =
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
    }
    catch {
        [System.Windows.MessageBox]::Show($error[0].Exception.Message, "Group Membership Update Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

$handler_ADAccountEnableButton_Click = 
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
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        [System.Windows.MessageBox]::Show("Unable to update account", "Account Enable/Disable Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

$handler_ADAccountRequiresSmartCardCheckbox_Click = 
{
    try {
        Set-ADUser $objPrincipal -SmartcardLogonRequired (!$objPrincipal.SmartcardLogonRequired)
     
        $script:objPrincipal = Get-ADUser $objPrincipal -Properties *
  
        $state = switch($objPrincipal.SmartcardLogonRequired) {
            $true { "Enabled";break }
            $false { "Disabled";break }
        }

        [System.Windows.MessageBox]::Show("SmartcardLogonRequired was $state. Please wait ~30 seconds for Active Directory to reflect the change.", "Account Enable/Disable Success",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        $error[0] | Out-String | Write-Error
        [System.Windows.MessageBox]::Show("Unable to update account", "SmartcardLogonRequired Enable/Disable Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# $handler_ADAccountExpiryDatePicker_DropDown =
# { 
#     Write-Host "Datepicker Clicked."
#     $Script:ADAccountExpiryDatePickerClicked = $true
# }

# $handler_ADAccountExpiryDatePicker_Changed =
# {   
#     try {
#         Write-Host "Datepicker Value Changed."
#         if ($Script:ADAccountExpiryDatePickerClicked) {
#             $expiry = $ADAccountExpiryDatePicker.Text
#             $ans = [System.Windows.MessageBox]::Show("Set Account Expiration to $($expiry)?", "Verify Action",`
#                 [System.Windows.MessageBoxButton]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
#             if ($ans -eq "Yes") {
#                 $Script:ADAccountExpiryDatePickerClicked = !$Script:ADAccountExpiryDatePickerClicked
#                 Set-ADAccountExpiration $objPrincipal -DateTime $expiry
#                 [System.Windows.MessageBox]::Show("Updated Account Expiration Date. Please wait ~30 seconds for Active Directory to reflect the change.", "Success",`
#                     [System.Windows.MessageBoxButton]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
#             }
#         }
#     }
#     catch {
#         $error[0] | Out-String | Write-Error
#         [System.Windows.MessageBox]::Show("Unable to update account expiration", "Account update Failed",`
#             [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
#     }
# }

$hander_ADAccountExpiryButton_Click =
{
    Clear-Console
    $DisplayInfoBox.Visible = $false
    $DisplayTitleLabel.Text = "Modify Account Expiration Date"
    $tableLayoutPanel3.Visible = $true
    $ADAccountExpiryDatePicker.Visible = $true
    $ADAccountClearExpiryButton.Visible = $true
    $ADAccountClearExpiryButton.Enabled = $objPrincipal.AccountExpirationDate -ne $null
    $UpdateExpiryButton.Visible = $true
}

$handler_ADAccountClearExpiryButton_Click = {
    try {
        Write-Host "Clear Expiry Button Clicked"
        $ans = [System.Windows.MessageBox]::Show("Clear Account Expiration?", "Verify Action",`
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($ans -eq "Yes") {
            Clear-ADAccountExpiration $objPrincipal
            [System.Windows.MessageBox]::Show("Account Expiration cleared. Please wait ~30 seconds for Active Directory to reflect the change.", "Success",`
                [System.Windows.MessageBoxButton]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        
            $DisplayInfoBox.Visible = $true
            $DisplayTitleLabel.Text = "Account Properties"
            $tableLayoutPanel3.Visible = $false
            $ADAccountClearExpiryButton.Visible = $false
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        [System.Windows.MessageBox]::Show("Unable to clear account expiration", "Expiry update Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

$handler_UpdateExpiryButton_Click = 
{
    try {
        Write-Host "Update Expiry Button Clicked"
        # if (!$ADAccountClearExpiryButton.Enabled -and $null -ne $objPrincipal.AccountExpirationDate) {
            # $ans = [System.Windows.MessageBox]::Show("Clear Account Expiration?", "Verify Action",`
            # [System.Windows.MessageBoxButton]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            # if ($ans -eq "Yes") {
            #     Clear-ADAccountExpiration $objPrincipal
            #     [System.Windows.MessageBox]::Show("Account Expiration cleared. Please wait ~30 seconds for Active Directory to reflect the change.", "Success",`
            #         [System.Windows.MessageBoxButton]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            # }
        # }
        # else {
            $expiry = $ADAccountExpiryDatePicker.Text
            $ans = [System.Windows.MessageBox]::Show("Set Account Expiration to $($expiry)?", "Verify Action",`
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($ans -eq "Yes") {
                $Script:ADAccountExpiryDatePickerClicked = !$Script:ADAccountExpiryDatePickerClicked
                Set-ADAccountExpiration $objPrincipal -DateTime $expiry
                [System.Windows.MessageBox]::Show("Updated Account Expiration Date. Please wait ~30 seconds for Active Directory to reflect the change.", "Success",`
                    [System.Windows.MessageBoxButton]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

                $DisplayInfoBox.Visible = $true
                $DisplayTitleLabel.Text = "Account Properties"
                $ADAccountExpiryDatePicker.Visible = $false
                $UpdateExpiryButton.Visible = $false
                $ADAccountClearExpiryButton.Visible = $false
                $tableLayoutPanel3.Visible = $false
            }
        # }
    }
    catch {
        $error[0] | Out-String | Write-Error
        [System.Windows.MessageBox]::Show("Unable to update account expiration", "Account update Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

$handler_ADReportsDisabledComputersButton_Click =
{
        Write-Host "Get DisabledComputers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Disabled Computers"
        $DisplayInfoBox.Text = (Get-DisabledComputers | Format-Table -AutoSize | Out-String)
}

$handler_ADReportsDomainControllersButton_Click =
{
        Write-Host "Get DomainControllers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Domain Controllers"
        $DisplayInfoBox.Text = (Get-DomainControllers | Format-Table -AutoSize | Out-String)
}

$handler_ADReportsInactiveComputersButton_Click =
{
        Write-Host "Get InactiveComputers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Inactive Computers"
        $DisplayInfoBox.Text = (Get-InactiveComputers | Format-Table -AutoSize | Out-String)
}

$handler_ADReportsInactiveUsersButton_Click =
{
        Write-Host "Get InactiveUsers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Inactive Users"
        # $user = Get-InactiveUsers | Out-GridView -Title 'Inactive Users' -PassThru
        # $ADPrincipalTextBox.Text = $user.SamAccountName
        Get-InactiveUsers
        $DisplayInfoBox.Text = (Import-Csv $env:TEMP\InactiveUsers.csv) | Out-String
}

$handler_ADReportsLockedOutUsersButton_Click =
{
        Write-Host "Get LockedOutUsers Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Locked Out Users"
        $DisplayInfoBox.Text = (Get-LockedOutUsers | Format-Table -AutoSize | Out-String)
}

$handler_ADReportsUsersNeverLoggedOnButton_Click =
{
        Write-Host "Get UsersNeverLoggedOn Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Never Logged On"
        $DisplayInfoBox.Text = (Get-UsersNeverLoggedOn | Format-Table -AutoSize | Out-String)
}

$handler_ADReportsUsersRecentlyCreatedButton_Click =
{
        Write-Host "Get UsersRecentlyCreated Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Recently Created"
        $DisplayInfoBox.Text = (Get-UsersRecentlyCreated | Format-Table -AutoSize | Out-String)
}

$handler_ADReportsUsersRecentlyDeletedButton_Click =
{
        Write-Host "Get UsersRecentlyDeleted Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Recently Deleted"
        $DisplayInfoBox.Text = (Get-UsersRecentlyDeleted | Format-Table -AutoSize | Out-String)
}

$handler_ADReportsUsersRecentlyModifiedButton_Click =
{
        Write-Host "Get UsersRecentlyModified Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Recently Modified"
        $DisplayInfoBox.Text = (Get-UsersRecentlyModified | Format-Table -AutoSize | Out-String)
}

$handler_ADReportsUsersWithoutManagerButton_Click =
{
        Write-Host "Get UsersWithoutManager Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Without Manager"
        $DisplayInfoBox.Text = (Get-UsersWithoutManager | Format-Table -AutoSize | Out-String)
}

$handler_formclose =
  {
    1..3 | ForEach-Object {[GC]::Collect()}
  
    $form.Dispose()
  }
#endregion

$form = New-Object System.Windows.Forms.Form
$screen = [System.Windows.Forms.SystemInformation]::VirtualScreen 

$form.Text = "Account Viewer and Updater"
$form.Name = "form"
$form.SuspendLayout()

# $form.AutoScaleDimensions =  New-Object System.Drawing.SizeF(96, 96)
# $form.AutoScaleMode  = [System.Windows.Forms.AutoScaleMode]::Dpi
# $form.AutoScale = $true

$form.FormBorderStyle = "FixedDialog"
$form.StartPosition = "CenterScreen"
$form.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = $screen.Width * .75
$System_Drawing_Size.Height = $screen.Height * .75
$form.ClientSize = $System_Drawing_Size
$form.StartPosition = "WindowsDefaultLocation"

#region configure the controls
#region Username label
$ADUserLabel.Text = "Enter a Username"
$ADUserLabel.AutoSize = $true
$ADUserLabel.Font = $BoldBoxFont
#endregion

#region Username input textbox
$ADPrincipalTextBox.Width = 150 # $form.Width * 0.3
$ADPrincipalTextBox.Height = 15
$ADPrincipalTextBox.Name = "ADUserInput"
$ADPrincipalTextBox.Multiline = $false
$ADPrincipalTextBox.Font = $BoxFont
#endregion

#region Lookup User Button
$ADLookupButton.Name = "ADLookupButton"
$ADLookupButton.AutoSize = $true
$ADLookupButton.AutoSizeMode = "GrowAndShrink"
$ADLookupButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
    -bor [System.Windows.Forms.AnchorStyles]::Left `
    -bor [System.Windows.Forms.AnchorStyles]::Bottom
$ADLookupButton.UseVisualStyleBackColor = $True
$ADLookupButton.Text = "Lookup User"
$ADLookupButton.Font = $BoxFont
$ADLookupButton.add_Click($handler_ADLookupButton_Click)
#endregion

#region search type label
$ADSearchTypeLabel.Text = "Search Type"
$ADSearchTypeLabel.AutoSize = $true
$ADSearchTypeLabel.Font = $BoldBoxFont
#endregion

#region user search radiobutton
$ADSearchUsersRadioButton.Name = "ADUserSearchUsersRadioButton"
$ADSearchUsersRadioButton.Text = "Users"
$ADSearchUsersRadioButton.Font = $BoxFont
$ADSearchUsersRadioButton.Checked = $true
$ADSearchUsersRadioButton.UseVisualStyleBackColor = $True
$ADSearchUsersRadioButton.add_Click($handler_ADSearchUsersRadioButton_Click)
#endregion

#region computer search radiobutton
$ADSearchComputersRadioButton.Name = "ADUserSearchComputersRadioButton"
$ADSearchComputersRadioButton.Text = "Computers"
$ADSearchComputersRadioButton.Font = $BoxFont
$ADSearchComputersRadioButton.Checked = $false
$ADSearchComputersRadioButton.UseVisualStyleBackColor = $True
$ADSearchComputersRadioButton.add_Click($handler_ADSearchComputersRadioButton_Click)
#endregion

#region service account search radiobutton
$ADSearchServiceAccountsRadioButton.Name = "ADUserSearchServiceAccountsRadioButton"
$ADSearchServiceAccountsRadioButton.Text = "Service Accounts"
$ADSearchServiceAccountsRadioButton.Font = $BoxFont
$ADSearchServiceAccountsRadioButton.AutoSize = $true
$ADSearchServiceAccountsRadioButton.Checked = $false
$ADSearchServiceAccountsRadioButton.UseVisualStyleBackColor = $True
$ADSearchServiceAccountsRadioButton.add_Click($handler_ADSearchServiceAccountsRadioButton_Click)
#endregion

#region AD Repors Label
$ADReportsLabel.Name = "ADReportsLabel"
$ADReportsLabel.Text = "Active Directory Reports"
$ADReportsLabel.Font = $BoldBoxFont
$ADReportsLabel.AutoSize = $true
$ADReportsLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
-bor [System.Windows.Forms.AnchorStyles]::Bottom `
-bor [System.Windows.Forms.AnchorStyles]::Left `
-bor [System.Windows.Forms.AnchorStyles]::Right
#endregion

#region AD Reports DisabledComputers button
$ADReportsDisabledComputersButton.Name = "ADReportsDisabledComputersButton"
$ADReportsDisabledComputersButton.Text = "Get Disabled Computers"
$ADReportsDisabledComputersButton.Font = $BoxFont
$ADReportsDisabledComputersButton.Autosize = $true
$ADReportsDisabledComputersButton.add_Click($handler_ADReportsDisabledComputersButton_Click)
#endregion

#region AD Reports DomainControllers button
$ADReportsDomainControllersButton.Name = "ADReportsDomainControllersButton"
$ADReportsDomainControllersButton.Text = "Get Domain Controllers"
$ADReportsDomainControllersButton.Font = $BoxFont
$ADReportsDomainControllersButton.Autosize = $true
$ADReportsDomainControllersButton.add_Click($handler_ADReportsDomainControllersButton_Click)
#endregion

#region AD Reports InactiveComputers button
$ADReportsInactiveComputersButton.Name = "ADReportsInactiveComputersButton"
$ADReportsInactiveComputersButton.Text = "Get Inactive Computers"
$ADReportsInactiveComputersButton.Font = $BoxFont
$ADReportsInactiveComputersButton.Autosize = $true
$ADReportsInactiveComputersButton.add_Click($handler_ADReportsInactiveComputersButton_Click)
#endregion

#region AD Reports InactiveUsers button
$ADReportsInactiveUsersButton.Name = "ADReportsInactiveUsersButton"
$ADReportsInactiveUsersButton.Text = "Get Inactive Users"
$ADReportsInactiveUsersButton.Font = $BoxFont
$ADReportsInactiveUsersButton.Autosize = $true
$ADReportsInactiveUsersButton.add_Click($handler_ADReportsInactiveUsersButton_Click)
#endregion

#region AD Reports LockedOutUsers button
$ADReportsLockedOutUsersButton.Name = "ADReportsLockedOutUsersButton"
$ADReportsLockedOutUsersButton.Text = "Get Locked Out Users"
$ADReportsLockedOutUsersButton.Font = $BoxFont
$ADReportsLockedOutUsersButton.Autosize = $true
$ADReportsLockedOutUsersButton.add_Click($handler_ADReportsLockedOutUsersButton_Click)
#endregion

#region AD Reports UsersNeverLoggedOn button
$ADReportsUsersNeverLoggedOnButton.Name = "ADReportsUsersNeverLoggedOnButton"
$ADReportsUsersNeverLoggedOnButton.Text = "Get Users Never Logged On"
$ADReportsUsersNeverLoggedOnButton.Font = $BoxFont
$ADReportsUsersNeverLoggedOnButton.Autosize = $true
$ADReportsUsersNeverLoggedOnButton.add_Click($handler_ADReportsUsersNeverLoggedOnButton_Click)
#endregion

#region AD Reports UsersRecentlyCreated button
$ADReportsUsersRecentlyCreatedButton.Name = "ADReportsUsersRecentlyCreatedButton"
$ADReportsUsersRecentlyCreatedButton.Text = "Get Users Recently Created"
$ADReportsUsersRecentlyCreatedButton.Font = $BoxFont
$ADReportsUsersRecentlyCreatedButton.Autosize = $true
$ADReportsUsersRecentlyCreatedButton.add_Click($handler_ADReportsUsersRecentlyCreatedButton_Click)
#endregion

#region AD Reports UsersRecentlyDeleted button
$ADReportsUsersRecentlyDeletedButton.Name = "ADReportsUsersRecentlyDeletedButton"
$ADReportsUsersRecentlyDeletedButton.Text = "Get Users Recently Deleted"
$ADReportsUsersRecentlyDeletedButton.Font = $BoxFont
$ADReportsUsersRecentlyDeletedButton.Autosize = $true
$ADReportsUsersRecentlyDeletedButton.add_Click($handler_ADReportsUsersRecentlyDeletedButton_Click)
#endregion

#region AD Reports UsersRecentlyModified button
$ADReportsUsersRecentlyModifiedButton.Name = "ADReportsUsersRecentlyModifiedButton"
$ADReportsUsersRecentlyModifiedButton.Text = "Get Users Recently Modified"
$ADReportsUsersRecentlyModifiedButton.Font = $BoxFont
$ADReportsUsersRecentlyModifiedButton.Autosize = $true
$ADReportsUsersRecentlyModifiedButton.add_Click($handler_ADReportsUsersRecentlyModifiedButton_Click)
#endregion

#region AD Reports UsersWithoutManager button
$ADReportsUsersWithoutManagerButton.Name = "ADReportsUsersWithoutManagerButton"
$ADReportsUsersWithoutManagerButton.Text = "Get Users Without Manager"
$ADReportsUsersWithoutManagerButton.Font = $BoxFont
$ADReportsUsersWithoutManagerButton.Autosize = $true
$ADReportsUsersWithoutManagerButton.add_Click($handler_ADReportsUsersWithoutManagerButton_Click)
#endregion

#region Account Status Label
$ADAccountStatusLabel.Name = "ADAccountStatusLabel"
$ADAccountStatusLabel.Text = "Account Status"
$ADAccountStatusLabel.Font = $BoldBoxFont
$ADAccountStatusLabel.AutoSize = $true
#endregion

#region Account Expiration Label
$ADAccountExpirationLabel.Name = "ADAccountExpirationLabel"
$ADAccountExpirationLabel.Text = "Account Expiration Date: $($objPrincipal.AccountExpirationDate)"
$ADAccountExpirationLabel.Font = $BoxFont
$ADAccountExpirationLabel.AutoSize = $true
#endregion

#region Account Enabled Label
$ADAccountEnableLabel.Name = "ADAccountEnabledLabel"
$ADAccountEnableLabel.Text = "Account Enabled: $($objPrincipal.Enabled)"
$ADAccountEnableLabel.Font = $BoxFont
$ADAccountEnableLabel.AutoSize = $true
#endregion

#region Account Locked Label
$ADAccountUnlockLabel.Name = "ADAccountUnlockedLabel"
$ADAccountUnlockLabel.Text = "Account Locked Out: $($objPrincipal.LockedOut)"
$ADAccountUnlockLabel.Font = $BoxFont
$ADAccountUnlockLabel.AutoSize = $true
#endregion

#region smartcard logon required Label
$ADAccountRequiresSmartcardLabel.Name = "ADAccountSmartcardRequiredLabel"
$ADAccountRequiresSmartcardLabel.Text = "Smartcard Required: $($objPrincipal.SmartcardLogonRequired)"
$ADAccountRequiresSmartcardLabel.Font = $BoxFont
$ADAccountRequiresSmartcardLabel.AutoSize = $true
#endregion

#region Display title Label
$DisplayTitleLabel.Name = "DisplayTitleLabel"
$DisplayTitleLabel.Font = $TitleFont
$DisplayTitleLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
-bor [System.Windows.Forms.AnchorStyles]::Bottom `
-bor [System.Windows.Forms.AnchorStyles]::Left `
-bor [System.Windows.Forms.AnchorStyles]::Right
#endregion

#region Display text box
$DisplayInfoBox.Name = "DisplayInfoBox"
$DisplayInfoBox.Multiline = $true
$DisplayInfoBox.Scrollbars = "Both"
$DisplayInfoBox.Readonly = $true
$DisplayInfoBox.Font = $ConsoleFont
# $DisplayInfoBox.Font = [System.Drawing.Font]::new($BoxFont.FontFamily, $BoxFont.Size-2, $BoxFont.Style)
$DisplayInfoBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
-bor [System.Windows.Forms.AnchorStyles]::Bottom `
-bor [System.Windows.Forms.AnchorStyles]::Left `
-bor [System.Windows.Forms.AnchorStyles]::Right
#endregion

#region account actions label
$ADAccountActionsLabel.Name = "ADAccountActionsLabel"
$ADAccountActionsLabel.Text = "Account Actions"
$ADAccountActionsLabel.Font = $BoldBoxFont
$ADAccountActionsLabel.AutoSize = $true
#endregion

#region account expiry button
$ADAccountSetExpiryButton.Name = "ADAccountSetExpiryButton"
$ADAccountSetExpiryButton.Text = "Modify Expiry"
$ADAccountSetExpiryButton.Font = $BoxFont
$ADAccountSetExpiryButton.AutoSize = $true
$ADAccountSetExpiryButton.add_Click($hander_ADAccountExpiryButton_Click)
#endregion

#region Account expiry datepicker
$ADAccountExpiryDatePicker.Name = "ADAccountExpiryDatePicker"
$ADAccountExpiryDatePicker.Font = $BoxFont
$ADAccountExpiryDatePicker.Format = "Custom"
$ADAccountExpiryDatePicker.CustomFormat = "ddd, dd MMM yyyy"
# $ADAccountExpiryDatePicker.add_DropDown($handler_ADAccountExpiryDatePicker_DropDown)
# $ADAccountExpiryDatePicker.add_ValueChanged($handler_ADAccountExpiryDatePicker_Changed)
#endregion

#region account clear expiry button
$ADAccountClearExpiryButton.Name = "ADAccountClearExpiryButton"
$ADAccountClearExpiryButton.Text = "Clear Account Expiry"
$ADAccountClearExpiryButton.Font = $BoxFont
$ADAccountClearExpiryButton.AutoSize = $true
$ADAccountClearExpiryButton.add_Click($handler_ADAccountClearExpiryButton_Click)
#endregion

#region update expiry button
$UpdateExpiryButton.Name = "UpdateExpiryButton"
$UpdateExpiryButton.Text = "Update Expiry"
$UpdateExpiryButton.Font = $BoxFont
$UpdateExpiryButton.AutoSize = $true
$UpdateExpiryButton.add_Click($handler_UpdateExpiryButton_Click)
#endregion

#region Enable/Disable Account button
$ADAccountEnableButton.Name = "ADAccountEnableButton"
$ADAccountEnableButton.Text = switch ($objPrincipal.Enabled) {
    $true { "Disable Account";break }
    $false { "Enable Account";break }
}
$ADAccountEnableButton.Font = $BoxFont
$ADAccountEnableButton.AutoSize = $true
$ADAccountEnableButton.add_Click($handler_ADAccountEnableButton_Click)
#endregion

#region Account requires smartcard checkbox
$ADAccountRequiresSmartcardCheckBox.Name = "ADAccountRequiresSmartcard"
$ADAccountRequiresSmartcardCheckBox.Text = "SmartcardLogonRequired"
$ADAccountRequiresSmartcardCheckBox.AutoSize = $true
$ADAccountRequiresSmartcardCheckBox.Font = $BoxFont
$ADAccountRequiresSmartcardCheckBox.Checked = $objPrincipal.SmartcardLogonRequired
$ADAccountRequiresSmartcardCheckBox.UseVisualStyleBackColor = $True
$ADAccountRequiresSmartcardCheckBox.add_Click($handler_ADAccountRequiresSmartCardCheckbox_Click)
#endregion

#region Enumerate group memberships Button
$ADGetGroupMembershipButton.Name = "ADGetGroupMembershipButton"
$ADGetGroupMembershipButton.AutoSize = $true
$ADGetGroupMembershipButton.UseVisualStyleBackColor = $True
$ADGetGroupMembershipButton.Text = "Get Group Membership"
$ADGetGroupMembershipButton.Font = $BoxFont
$ADGetGroupMembershipButton.add_Click($handler_ADGetGroupMembershipButton_Click)
#endregion

#region AD Groups List box
$ADGroupsBox.SelectionMode = "MultiExtended"
$ADGroupsBox.Name = "ADGroupsBox"
$ADGroupsBox.Font = $BoxFont
$ADGroupsBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
-bor [System.Windows.Forms.AnchorStyles]::Bottom `
-bor [System.Windows.Forms.AnchorStyles]::Left `
-bor [System.Windows.Forms.AnchorStyles]::Right
#endregion

#region RemoveGroups button
$RemoveGroupButton.Font = $BoxFont
$RemoveGroupButton.Name = "RemoveGroupButton"
$RemoveGroupButton.Text = "<-"
$RemoveGroupButton.Anchor = [System.Windows.Forms.AnchorStyles]::Left `
-bor [System.Windows.Forms.AnchorStyles]::Right
$RemoveGroupButton.add_Click($handler_RemoveGroupButton_Click)
#endregion

#region AddGroups button
$AddGroupButton.Font = $BoxFont
$AddGroupButton.Name = "AddGroupButton"
$AddGroupButton.Text = "->"
$AddGroupButton.Anchor = [System.Windows.Forms.AnchorStyles]::Left `
-bor [System.Windows.Forms.AnchorStyles]::Right
$AddGroupButton.add_Click($handler_AddGroupButton_Click)
#endregion

#region AD Group Membership List box
$ADGroupMembershipBox.SelectionMode = "MultiExtended"
$ADGroupMembershipBox.Name = "ADGroupMembershipBox"
$ADGroupMembershipBox.Font = $BoxFont
$ADGroupMembershipBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
-bor [System.Windows.Forms.AnchorStyles]::Bottom `
-bor [System.Windows.Forms.AnchorStyles]::Left `
-bor [System.Windows.Forms.AnchorStyles]::Right
#endregion

#region Update group memberships Button
$UpdateGroupMembershipsButton.Name = "UpdateGroupMembershipsButton"
$UpdateGroupMembershipsButton.UseVisualStyleBackColor = $True
$UpdateGroupMembershipsButton.Text = "Update Group Membership"
$UpdateGroupMembershipsButton.Font = $BoxFont
$UpdateGroupMembershipsButton.add_Click($handler_UpdateGroupMembershipButton_Click)
#endregion
#endregion

$form.Controls.AddRange(@($tableLayoutPanel1))
$form.ResumeLayout()

# set control visibility on form load
Reset-Form
# $ADUserLabel.Visible = $true
# $ADPrincipalTextBox.Visible = $true
# $ADLookupButton.Visible = $true
# $DisplayInfoBox.Visible = $true
# $ADGetGroupMembershipButton.Visible = $false
# $UpdateGroupMembershipsButton.Visible = $false
# $ADAccountStatusLabel.Visible = $false
# $ADAccountExpirationLabel.Visible = $false
# $ADAccountEnableLabel.Visible = $false
# $ADAccountUnlockLabel.Visible = $false

$form.Add_FormClosed($handler_formclose)

#Show the Form
$form.ShowDialog()
# $null = [Windows.Forms.Application]::Run($form)