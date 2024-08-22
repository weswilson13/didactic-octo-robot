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
function Reset-Form {
    param(
        [switch]$ExceptPrincipal
    )

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
    $ADAccountResetAccountPasswordButton.Visible = $false
    $ADAccountUnlockUserAccountButton.Visible = $false
    $ADReportsTableLayoutPanel.Visible = $false
    $ValidateNPUserButton.Visible = $false
    $OptionButtonsTableLayoutPanel.Visible= $true

    Clear-Console
}
function Get-ConnectionParameters {
    param(
        [string]$IniSection
    )

    $ini = Get-IniContent .\config.ini

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
        $ini = Get-IniContent .\config.ini

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
#dot sourced functions
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

#region font objects
$TitleFont = New-Object System.Drawing.Font("Calibri",24,[Drawing.FontStyle]::Bold)
# $BodyFont = New-Object System.Drawing.Font("Calibri",18,[Drawing.FontStyle]::Bold)
$BoxFont = New-Object System.Drawing.Font("Calibri", 12, [Drawing.FontStyle]::Regular)
$BoldBoxFont = New-Object System.Drawing.Font("Calibri", 12, [Drawing.FontStyle]::Bold)
$ConsoleFont = New-Object System.Drawing.Font("Lucida Console", 10, [Drawing.FontStyle]::Regular)
#endregion

#region create the controls
#region Labels
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
$OptionButtonsLabel = New-Object System.Windows.Forms.Label
#endregion

#region Text boxes
$ADPrincipalTextBox = New-Object System.Windows.Forms.TextBox
$NewPasswordTextBox = New-Object System.Windows.Forms.TextBox
#endregion

#region RichTextBoxes
$DisplayInfoBox = New-Object System.Windows.Forms.RichTextBox
#endregion

#region Buttons
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
$ADAccountUnlockUserAccountButton = New-Object System.Windows.Forms.Button
$ADAccountResetAccountPasswordButton = New-Object System.Windows.Forms.Button
$UpdatePasswordButton = New-Object System.Windows.Forms.Button
$DisplayReportsPanelButton = New-Object System.Windows.Forms.Button
$ValidateNPUserButton = New-Object System.Windows.Forms.Button
#endregion

#region ListBoxes
$ADGroupsBox = New-Object System.Windows.Forms.ListBox
$ADGroupMembershipBox = New-Object System.Windows.Forms.ListBox
#endregion

#region Datepicker
$ADAccountExpiryDatePicker = New-Object System.Windows.Forms.DateTimePicker
#endregion

#region RadioButtons
$ADSearchUsersRadioButton = New-Object System.Windows.Forms.RadioButton
$ADSearchComputersRadioButton = New-Object System.Windows.Forms.RadioButton
$ADSearchServiceAccountsRadioButton = New-Object System.Windows.Forms.RadioButton
#endregion

#region Checkboxes
$ADAccountRequiresSmartcardCheckBox = New-Object System.Windows.Forms.CheckBox
# $ADAccountExpiryCheckbox = New-Object System.Windows.Forms.CheckBox
#endregion

#region TableLayoutPanels
#region main table layout panel
$MainTableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$MainTableLayoutPanel.RowCount = 3 #how many rows
$MainTableLayoutPanel.ColumnCount = 6 #how many columns
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
$tableLayoutPanel2.Controls.Add($ADAccountUnlockUserAccountButton,3,3)
$tableLayoutPanel2.Controls.Add($ADAccountRequiresSmartcardCheckBox,3,4)
    #column 5
$tableLayoutPanel2.Controls.Add($ADAccountResetAccountPasswordButton,4,1)
$tableLayoutPanel2.Controls.Add($ADGetGroupMembershipButton,4,2)
$tableLayoutPanel2.Controls.Add($UpdateGroupMembershipsButton,4,2)
$tableLayoutPanel2.Controls.Add($ValidateNPUserButton,4,3)

$tableLayoutPanel2.SetColumnSpan($ADAccountActionsLabel,2)

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
# $ADReportsTableLayoutPanel.CellBorderStyle = "Inset" 

$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null

$ADReportsTableLayoutPanel.SetColumnSpan($ADReportsLabel,3)

$ADReportsTableLayoutPanel.Controls.Add($ADReportsLabel,0,0)
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

$MainTableLayoutPanel.Controls.Add($tableLayoutPanel2,0,0)
$MainTableLayoutPanel.Controls.Add($ExpiryTableLayoutPanel,1,2)
$tableLayoutPanel2.Controls.Add($ADReportsTableLayoutPanel,2,0)
$tableLayoutPanel2.Controls.Add($OptionButtonsTableLayoutPanel,2,0)

$MainTableLayoutPanel.SetColumnSpan($tableLayoutPanel2,6)
$tableLayoutPanel2.SetColumnSpan($ADReportsTableLayoutPanel,3)
$tableLayoutPanel2.SetColumnSpan($OptionButtonsTableLayoutPanel,3)
$tableLayoutPanel2.SetRowSpan($ADReportsTableLayoutPanel,5)
$tableLayoutPanel2.SetRowSpan($OptionButtonsTableLayoutPanel,5)
#endregion tablelayoutpanels
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
            Clear-OptionsPanel 
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
        
        Write-Log -Message "$env:USERNAME $($message.Replace('Finished modifying', 'modified'))" -Severity Information
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
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

$handler_ADAccountRequiresSmartCardCheckbox_Click = 
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

$hander_ADAccountExpiryButton_Click =
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

$handler_ADAccountClearExpiryButton_Click = 
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

$handler_UpdateExpiryButton_Click = 
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
        Write-Host "Get Users Recently Modified Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Recently Modified"
        $DisplayInfoBox.Text = (Get-UsersRecentlyModified | Format-Table -AutoSize | Out-String)
}

$handler_ADReportsUsersWithoutManagerButton_Click =
{
        Write-Host "Get Users Without Manager Report"
        Clear-Console
        $DisplayTitleLabel.Text = "Users Without Manager"
        $DisplayInfoBox.Text = (Get-UsersWithoutManager | Format-Table -AutoSize | Out-String)
}
#endregion

$handler_ADAccountUnlockUserAccountButton_Click =
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

$handler_ADAccountResetAccountPasswordButton_Click =
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

$handler_UpdatePasswordButton_Click =
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

$handler_DisplayReportsPanelButton_Click = 
{
    $OptionButtonsTableLayoutPanel.Visible = $false
    $ADReportsTableLayoutPanel.Visible = $true
}

$handler_ValidateNPUserButton_Click = 
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
        
        # get the users PID from NOTEPAD
        $mapping = Get-UserMapping
        $ini = Get-IniContent .\config.ini 
        $pidQuery = $ini.NotepadDbConfig.PIDQuery
        $pidQuery = $pidQuery.replace('<firstname>', $objPrincipal.$($mapping.First_Name))
        $pidQuery = $pidQuery.replace('<lastname>', $objPrincipal.$($mapping.Last_Name))
        $pidQuery = $pidQuery.replace('<rate>', $objPrincipal.$($mapping.Rate))
        Write-Host $pidQuery

        $sqlParameters["Query"] = $pidQuery
        $_PID = Invoke-Sqlcmd @sqlParameters
        if (!$_PID) { throw "A PID for user $($objPrincipal.SamAccountName) was not found in NOTEPAD." }
        
        # update the login id in Notepad
        $updateQuery = $ini.NotepadDbConfig.UpdateQuery
        $updateQuery = $updateQuery.Replace('<username>', $objPrincipal.UserPrincipalName)
        $updateQuery = $updateQuery.Replace('<pid>', $_PID.PID)
        Write-Host $updateQuery

        $sqlParameters["Query"] = $updateQuery
        Invoke-Sqlcmd @sqlParameters

        Write-Log -Message "$env:USERNAME validated $($objPrincipal.SamAccountName) against NOTEPAD database"
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-log -Message $error[0].Exception.Message -Severity Error
        [System.Windows.MessageBox]::Show("Unable to validate user against NOTEPAD", "NOTEPAD Validation Failed",`
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

$handler_formclose =
  {
    1..3 | ForEach-Object {[GC]::Collect()}
    
    Write-Log -Message "$env:USERNAME ended the session." -Severity Information 
    
    $form.Dispose()

    Import-SessionLog
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
# $form.StartPosition = "WindowsDefaultLocation"

#region configure the controls
#region lookup principal
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
#endregion lookup principal

#region search type choices (user, computer, service account)
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
#endregion search type choices

#region option button panel controls (Display Report panel, Validate NP User)
#region Option Buttons Label
$OptionButtonsLabel.Name = "OptionButtonsLabel"
$OptionButtonsLabel.Text = "Other Options"
$OptionButtonsLabel.Font = $BoldBoxFont
$OptionButtonsLabel.AutoSize = $true
$OptionButtonsLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
    -bor [System.Windows.Forms.AnchorStyles]::Bottom `
    -bor [System.Windows.Forms.AnchorStyles]::Left `
    -bor [System.Windows.Forms.AnchorStyles]::Right
#endregion

#region display report panel button
$DisplayReportsPanelButton.Name = "DisplayReportsPanelButton"
$DisplayReportsPanelButton.Text = "Active Directory Reports"
$DisplayReportsPanelButton.Font = $BoxFont
$DisplayReportsPanelButton.AutoSize = $true
$DisplayReportsPanelButton.add_Click($handler_DisplayReportsPanelButton_Click)
#endregion

#region validate NP user
$ValidateNPUserButton.Name = "ValidateNPUserButton"
$ValidateNPUserButton.Text = "Validate Notepad User"
$ValidateNPUserButton.Font = $BoxFont
$ValidateNPUserButton.AutoSize = $true
$ValidateNPUserButton.add_Click($handler_ValidateNPUserButton_Click)
#endregion
#endregion option button panel controls

#region reports controls
#region AD Reports Label
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
#endregion reports controls

#region account status labels
#region Account Status Label
$ADAccountStatusLabel.Name = "ADAccountStatusLabel"
$ADAccountStatusLabel.Text = "Account Status"
$ADAccountStatusLabel.Font = $BoldBoxFont
$ADAccountStatusLabel.AutoSize = $true
#endregion

#region Account Expiration Label
$ADAccountExpirationLabel.Name = "ADAccountExpirationLabel"
$ADAccountExpirationLabel.Text = "Account Expiration Date: "
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
#endregion account status labels

#region console controls (Display title, Display text box)
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
#endregion console controls

#region account actions (modify expiry, reset pwd, unlock account, enable/disable account, smartcardlogon, group membership)
#region account actions label
$ADAccountActionsLabel.Name = "ADAccountActionsLabel"
$ADAccountActionsLabel.Text = "Account Actions"
$ADAccountActionsLabel.Font = $BoldBoxFont
$ADAccountActionsLabel.AutoSize = $true
$ADAccountActionsLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
    -bor [System.Windows.Forms.AnchorStyles]::Bottom `
    -bor [System.Windows.Forms.AnchorStyles]::Left `
    -bor [System.Windows.Forms.AnchorStyles]::Right
#endregion

#region modify expiry
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
#endregion

#region reset user password
#region AD Reset Account Password button
$ADAccountResetAccountPasswordButton.Name = "ADReportsAccountPasswordButton"
$ADAccountResetAccountPasswordButton.Text = "Reset Account Password"
$ADAccountResetAccountPasswordButton.Font = $BoxFont
$ADAccountResetAccountPasswordButton.Autosize = $true
$ADAccountResetAccountPasswordButton.add_Click($handler_ADAccountResetAccountPasswordButton_Click)
#endregion

#region New Password Text Box
$NewPasswordTextBox.Name = "NewPasswordTextBox"
$NewPasswordTextBox.Font = $BoxFont
$NewPasswordTextBox.PasswordChar = "*"
$NewPasswordTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
    -bor [System.Windows.Forms.AnchorStyles]::Bottom `
    -bor [System.Windows.Forms.AnchorStyles]::Left `
    -bor [System.Windows.Forms.AnchorStyles]::Right
#endregion

#region Update Password Button
$UpdatePasswordButton.Name = "UpdatePasswordButton"
$UpdatePasswordButton.Text = "Reset Password"
$UpdatePasswordButton.AutoSize = $true
$UpdatePasswordButton.add_Click($handler_UpdatePasswordButton_Click)
#endregion
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

#region AD Unlock User Account button
$ADAccountUnlockUserAccountButton.Name = "ADReportsUnlockUserAccountButton"
$ADAccountUnlockUserAccountButton.Text = "Unlock Account"
$ADAccountUnlockUserAccountButton.Font = $BoxFont
$ADAccountUnlockUserAccountButton.Autosize = $true
$ADAccountUnlockUserAccountButton.add_Click($handler_ADAccountUnlockUserAccountButton_Click)
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

#region group membership
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
#endregion group membership
#endregion account actions

$form.Controls.AddRange(@($MainTableLayoutPanel))
$form.ResumeLayout()

# set control visibility on form load
Reset-Form

$form.Add_FormClosed($handler_formclose)

#Show the Form
Write-Log -Message "$env:USERNAME started a new session." -Severity Information 
$form.ShowDialog()