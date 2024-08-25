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
    Clear-GroupControlsPanel
    Clear-NTKAssignmentPanel
    Clear-UserInformationPanel
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
function Clear-NTKAssignmentPanel {
    $NTKAssignmentPanel.Visible = $false
}
function Clear-UserInformationPanel {
    $ADUpdateUserInformationPanel.Visible = $false
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
    $ADUpdateUserInformationButton.Visible = $false
    $ValidateNPUserButton.Visible = $false
    $OptionButtonsTableLayoutPanel.Visible = $true
    $DomainServersTableLayoutPanel.Visible = $true

    Clear-GroupControlsPanel
    Clear-Console
}
function Get-ConnectionParameters {
    param(
        [string]$IniSection,

        [Validateset('InvokeSqlCmd','WriteSqlTableData')]
        [string]$Cmdlet
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

    $obj =  switch ($Cmdlet) {
        'WriteSqlTableData' {
            [hashtable]@{
                ServerInstance = $ini.$IniSection.SqlServerInstance
                DatabaseName = $ini.$IniSection.Database
                SchemaName = $ini.$IniSection.Schema
                TableName = $ini.$IniSection.Table
                Encrypt = $encrypt
                TrustServerCertificate = $trustServerCertificate
            }
        }
        'InvokeSqlCmd' {
            [hashtable]@{
                ServerInstance = $ini.$IniSection.SqlServerInstance
                Database = $ini.$IniSection.Database
                Encrypt = $encrypt
                TrustServerCertificate = $trustServerCertificate
            }
        }
    }

    return $obj
}
function Import-SessionLog {
    try {
        Write-Host "Importing Session Log"
        
        $connectionParams = Get-ConnectionParameters -IniSection LoggerConfig -Cmdlet WriteSqlTableData
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

        Write-Log -Message "Importing session logs for user $env:USERNAME" -Severity Information
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
            PRD = $ini.UserMappingNPtoAD.PRD
        }
    }
    catch {
        $error[0] | Out-String | Write-Error
        Write-Log -Message $error[0].Exception.Message -Severity Information
    }
}
function New-ErrorMessage {
    [CmdletBinding()]
    Param(
        [string]$ErrorMessage,
        [string]$MessageTitle
    )

    $error[0] | Out-String | Write-Error
    Write-Log -Message $error[0].Exception.Message -Severity Error
    [System.Windows.MessageBox]::Show($ErrorMessage, $MessageTitle,`
        [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}
function Reset-GroupLists {
    param()

    Write-Host "Resetting group list boxes"
    $ADGroupMembershipBox.Items.Clear()
    $ADGroupsBox.Items.Clear()
    Get-ADGroup -Filter 'GroupScope -ne "DomainLocal" -and Name -ne "Domain Users"' | 
        Where-Object { $_.DistinguishedName -notin $objPrincipal.MemberOf } | 
        ForEach-Object {
            $ADGroupsBox.Items.Add($PSItem.Name)
        }
    $objPrincipal.MemberOf.ForEach({$ADGroupMembershipBox.Items.Add((Get-ADGroup $PSItem).SamAccountName)})
}

#dot sourced functions
. "$PSScriptRoot\Functions\Event-Handlers.ps1"
. "$PSScriptRoot\Functions\Clear-NTKGroups.ps1"
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
$ButtonFont = New-Object System.Drawing.Font($BoxFont.FontFamily, 10, $BoxFont.Style)
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
        UseVisualStyleBackColor = $true
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
        BackColor = 'LightBlue'
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
$ADAccountSetExpiryButton.add_Click({handler_ADAccountExpiryButton_Click})
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
        # PasswordChar = "*"
        UseSystemPasswordChar = $true
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

#region upate user information region
#region update user information button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "ADUpdateUserInformationButton"
        Text = "Modify User Info"
        Font = $BoxFont
        Autosize = $true
    }
}
$ADUpdateUserInformationButton = New-Object @objParams
$ADUpdateUserInformationButton.add_Click({handler_ADUpdateUserInformationButton_Click})
#endregion

#region user information text boxes and lables
$ADUserInfoAttributes = 'Last Name','First Name','Rate','Office','Office Number','PRD','Description'
@('TextBox','Label') | ForEach-Object {
    foreach ($item in $ADUserInfoAttributes) {
        $objParams = @{
            TypeName = "System.Windows.Forms.$PSItem"
            Property = @{
                Name = "ADUser" + $item.Replace(' ','') + $PSItem
                Text = $item
                Font = $BoxFont
                AutoSize = $true
                Dock = "Fill"
            }
        }
        New-Variable -Name $objParams.Property.Name -Value (New-Object @objParams) -Force -ErrorAction SilentlyContinue
    }
}

#region set up auto complete for Rate and Office text boxes
$sqlParameters = Get-ConnectionParameters -IniSection NotepadDbConfig -Cmdlet InvokeSqlCmd
$rates = Invoke-Sqlcmd @sqlParameters -Query $ini.NotepadDbConfig.RateQuery
$offices = Invoke-Sqlcmd @sqlParameters -Query $ini.NotepadDbConfig.OfficeQuery

$rateSource = New-Object System.Windows.Forms.AutoCompleteStringCollection
$officeSource = New-Object System.Windows.Forms.AutoCompleteStringCollection
$rateSource.AddRange($rates.Prefix)
$officeSource.AddRange($offices.Office)
$ADUserRateTextBox.AutoCompleteSource = 'CustomSource'
$ADUserRateTextBox.AutoCompleteCustomSource = $rateSource
$ADUserRateTextBox.AutoCompleteMode = 'SuggestAppend'
$ADUserOfficeTextBox.AutoCompleteSource = 'CustomSource'
$ADUserOfficeTextBox.AutoCompleteCustomSource = $officeSource
$ADUserOfficeTextBox.AutoCompleteMode = 'SuggestAppend'
#endregion auto complete for Rate and Office text boxes
#endregion user information text boxes and labels

#region user office phone masktextbox
$objParams = @{
    TypeName = "System.Windows.Forms.MaskedTextBox"
    Property = @{
        Name = "ADUserOfficeNumberTextBox"
        Mask = "(###) ###-####"
        Font = $BoxFont
        AutoSize = $true
        Dock = "Fill"
    }
}
$ADUserOfficeNumberTextBox = New-Object @objParams
#endregion user office phone

#region user PRD datepicker
$objParams = @{
    TypeName = 'System.Windows.Forms.DateTimePicker'
    Property = @{
        Name = "ADUserPRDDatePicker"
        Font = $BoxFont
        Format = "Custom"
        CustomFormat = "ddd, dd MMM yyyy"
    }
}
$ADUserPRDTextBox = New-Object @objParams
#nedregion user PRD datepicker

#region Update user info button
$objParams =@{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = 'SetUserInfoButton'
        Text = "Update User`nInformation"
        Font = $BoxFont
        AutoSize = $true
    }
}
$SetUserInfoButton = New-Object @objParams
$SetUserInfoButton.add_Click({handler_SetUserInfoButton_Click})
#endregion update user info button

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
        Text = "Update`nMembership"
        Font = $ButtonFont
        AutoSize = $true
        Enabled = $false
        UseVisualStyleBackColor = $true
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
    }
}
$UpdateGroupMembershipsButton = New-Object @objParams
$UpdateGroupMembershipsButton.add_Click({handler_UpdateGroupMembershipButton_Click})
#endregion
#endregion group membership
#endregion account actions

#region NTK controls
#region NTK Button
$objParams = @{
    TypeName = 'System.Windows.Forms.Button'
    Property = @{
        Name = "NTKAssignmentButton"
        Text = "Assign`nNTK Groups"
        Font = $ButtonFont
        AutoSize = $true
        Enabled = $false
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
    }
}
$NTKAssignmentButton = New-Object @objParams
$NTKAssignmentButton.add_Click({handler_NTKAssignmentButton_Click})
#endregion NTK button

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
$NoNTKRadioButton.add_Click({handler_NTKRadioButton_Click -NTKAssignment None})
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
$NonNuclearNTKRadioButton.add_Click({handler_NTKRadioButton_Click -NTKAssignment NonNuclearTrained})
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
$NuclearNTKRadioButton.add_Click({handler_NTKRadioButton_Click -NTKAssignment NuclearTrained})
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
$IsdNTKRadioButton.add_Click({handler_NTKRadioButton_Click -NTKAssignment InformationSecurityDepartment})
#endregion ISD NTK radiobutton

#region Security NTK radiobutton
$objParams = @{
    TypeName = 'System.Windows.Forms.RadioButton'
    Property = @{
        Name = "SecurityNTKRadioButton"
        Text = "Physical Security`n(ATO, DAD, CSM, MAA, Director DTS, Director DTP, ISD)"
        Font = $BoxFont
        AutoSize = $true
    }
}
$SecurityNTKRadioButton = New-Object @objParams
$SecurityNTKRadioButton.add_Click({handler_NTKRadioButton_Click -NTKAssignment PhysicalSecurity})
#endregion Security NTK radiobutton

#region Senior Staff NTK radiobutton
$objParams = @{
    TypeName = 'System.Windows.Forms.RadioButton'
    Property = @{
        Name = "SeniorStaffNTKRadioButton"
        Text = "Senior Staff (CO, XO, DOS-A, DOS-P, CMC)"
        Font = $BoxFont
        AutoSize = $true
    }
}
$SeniorStaffNTKRadioButton = New-Object @objParams
$SeniorStaffNTKRadioButton.add_Click({handler_NTKRadioButton_Click -NTKAssignment SeniorStaff})
#endregion Senior Staff NTK radiobutton

#endregion NTK controls
#endregion configure individual controls

#region TableLayoutPanels
#region main table layout panel
$objParams = @{
    TypeName = 'System.Windows.Forms.TableLayoutPanel'
    Property = @{
        Name = "MainTableLayoutPanel"
        RowCount = 3 #how many rows
        ColumnCount = 6 #how many columns
        Dock = "Fill"
        BorderStyle = "Fixed3D"
        Anchor =[System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
        # CellBorderStyle = "Inset"
    }
}
$MainTableLayoutPanel = New-Object @objParams

$MainTableLayoutPanel.SetColumnSpan($DisplayTitleLabel,$MainTableLayoutPanel.ColumnCount)
$MainTableLayoutPanel.SetColumnSpan($DisplayInfoBox,$MainTableLayoutPanel.ColumnCount)
$MainTableLayoutPanel.SetColumnSpan($ADAccountClearExpiryButton,3)
$MainTableLayoutPanel.SetRowSpan($DisplayInfoBox,2)

$MainTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 30))) | Out-Null
$MainTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 8))) | Out-Null
$MainTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 62))) | Out-Null

$MainTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,1))) | Out-Null
$MainTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$MainTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,5))) | Out-Null
$MainTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,5))) | Out-Null
$MainTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$MainTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,49))) | Out-Null

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
#endregion main table

#region tablelayoutpanel2
$objParams = @{
    TypeName = 'System.Windows.Forms.TableLayoutPanel'
    Property = @{
        Name = "TableLayoutPanel2"
        RowCount = 5
        ColumnCount = 5
        Dock = "Fill"
        Anchor =[System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
        # CellBorderStyle = "Inset"
    }
}
$tableLayoutPanel2 = New-Object @objParams

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
$tableLayoutPanel2.Controls.Add($ADUpdateUserInformationButton,4,3)
$tableLayoutPanel2.Controls.Add($ValidateNPUserButton,4,4)

$tableLayoutPanel2.SetColumnSpan($ADAccountActionsLabel,2)
$tableLayoutPanel2.SetRowSpan($ADLookupButton,2)
#endregion tablelayoutpanel2

#region Account Expiration Panel
$objParams =@{
    TypeName = 'System.Windows.Forms.TableLayoutPanel'
    Property = @{
        Name = "AccountExpiryPanel"
        RowCount = 3
        ColumnCount = 1
        Dock = "Fill"
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
        # CellBorderStyle = "Inset"
    }
}
$ExpiryTableLayoutPanel = New-Object @objParams

$ExpiryTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null
$ExpiryTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null
$ExpiryTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null

$ExpiryTableLayoutPanel.Controls.Add($ADAccountExpiryDatePicker,0,0)
$ExpiryTableLayoutPanel.Controls.Add($NewPasswordTextBox,0,0)
$ExpiryTableLayoutPanel.Controls.Add($UpdateExpiryButton,0,2)
$ExpiryTableLayoutPanel.Controls.Add($UpdatePasswordButton,0,2)
#endregion account expiration panel

#region Reports Panel
$objParams = @{
    TypeName = 'System.Windows.Forms.TableLayoutPanel'
    Property = @{
        RowCount = 5 #how many rows
        ColumnCount = 3 #how many columns
        BorderStyle = "Fixed3D"
        Dock = "Fill"
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
        # CellBorderStyle = "Outset"
    }
}
$ADReportsTableLayoutPanel = New-Object @objParams

$ADReportsTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33.3))) | Out-Null
$ADReportsTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33.3))) | Out-Null
$ADReportsTableLayoutPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33.3))) | Out-Null

$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$ADReportsTableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null

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
#endregion reports panel

#region Options Buttons Panel
$objParams = @{
    TypeName = 'System.Windows.Forms.TableLayoutPanel'
    Property = @{
        Name = "OptionButtonsTableLayoutPanel"
        RowCount = 5
        ColumnCount = 3
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
        Dock = 'Fill'
        # CellBorderStyle = "Inset"
    }
}
$OptionButtonsTableLayoutPanel = New-Object @objParams
$OptionButtonsRowSpan = 5

$OptionButtonsTableLayoutPanel.SetColumnSpan($OptionButtonsLabel,3)

$OptionButtonsTableLayoutPanel.Controls.Add($OptionButtonsLabel,0,0)
$OptionButtonsTableLayoutPanel.Controls.Add($DisplayReportsPanelButton,0,1)
#endregion option buttons panel

#region Domain Servers Panel
$objParams = @{
    TypeName = 'System.Windows.Forms.TableLayoutPanel'
    Property = @{
        Name = "DomainServersPanel"
        RowCount = 1
        ColumnCount = 6
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
        Dock = "Fill"
#       CellBorderStyle = "Outset"
    }
}
$DomainServersTableLayoutPanel = New-Object @objParams

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
#endregion domain servers panel

#region Group controls Panel
$objParams = @{
    TypeName = 'System.Windows.Forms.TableLayoutPanel'
    Property = @{
        Name = "GroupControlsPanel"
        RowCount = 7
        ColumnCount = 2
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
        Dock = "Fill"
        BorderStyle = "None"
        # CellBorderStyle = "Inset"
    }
}
$GroupControlsTableLayoutPanel = New-Object @objParams

$GroupControlsTableLayoutPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$GroupControlsTableLayoutPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,80))) | Out-Null

$GroupControlsTableLayoutPanel.Controls.Add($UpdateGroupMembershipsButton,0,1)
$GroupControlsTableLayoutPanel.Controls.Add($NTKAssignmentButton,0,2)
#endregion group controls panel

#region NTK assignment Panel
$objParams = @{
    TypeName = 'System.Windows.Forms.TableLayoutPanel'
    Property = @{
        Name = "NTKAssignmentPanel"
        RowCount = 7
        ColumnCount = 1
        BackColor = 'Yellow'
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
        Dock = "Fill"
        BorderStyle = "None"
        # CellBorderStyle = "Inset"
    }
}
$NTKAssignmentPanel = New-Object @objParams
$NTKAssignmentPanel.Controls.Add($NTKLabel,0,0)
$NTKAssignmentPanel.Controls.Add($NoNTKRadioButton,0,1)
$NTKAssignmentPanel.Controls.Add($NonNuclearNTKRadioButton,0,2)
$NTKAssignmentPanel.Controls.Add($NuclearNTKRadioButton,0,3)
$NTKAssignmentPanel.Controls.Add($IsdNTKRadioButton,0,4)
$NTKAssignmentPanel.Controls.Add($SecurityNTKRadioButton,0,5)
$NTKAssignmentPanel.Controls.Add($SeniorStaffNTKRadioButton,0,6)
#endregion NTK assignment panel

#region Update user information panel
$objParams = @{
    TypeName = 'System.Windows.Forms.TableLayoutPanel'
    Property = @{
        Name = "UpdateUserInformationPanel"
        RowCount = 5 #how many rows
        ColumnCount = 5 #how many columns
        BorderStyle = "Fixed3D"
        Dock = "Fill"
        Anchor = [System.Windows.Forms.AnchorStyles]::Top `
            -bor [System.Windows.Forms.AnchorStyles]::Bottom `
            -bor [System.Windows.Forms.AnchorStyles]::Left `
            -bor [System.Windows.Forms.AnchorStyles]::Right
        # CellBorderStyle = "Outset"
    }
}
$ADUpdateUserInformationPanel = New-Object @objParams

$ADUpdateUserInformationPanel.SetColumnSpan($ADUserDescriptionTextBox,3)
$ADUpdateUserInformationPanel.SetRowSpan($SetUserInfoButton,2)

$ADUpdateUserInformationPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,10))) | Out-Null
$ADUpdateUserInformationPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$ADUpdateUserInformationPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,10))) | Out-Null
$ADUpdateUserInformationPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,20))) | Out-Null
$ADUpdateUserInformationPanel.ColumnStyles.Add((new-object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,40))) | Out-Null

# $ADUpdateUserInformationPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 10))) | Out-Null
# $ADUpdateUserInformationPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 10))) | Out-Null
# $ADUpdateUserInformationPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 10))) | Out-Null
# $ADUpdateUserInformationPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 10))) | Out-Null
# $ADUpdateUserInformationPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 10))) | Out-Null

$ADUpdateUserInformationPanel.Controls.Add($ADUserFirstNameLabel,0,0)
$ADUpdateUserInformationPanel.Controls.Add($ADUserFirstNameTextBox,1,0)
$ADUpdateUserInformationPanel.Controls.Add($ADUserLastNameLabel,2,0)
$ADUpdateUserInformationPanel.Controls.Add($ADUserLastNameTextBox,3,0)
$ADUpdateUserInformationPanel.Controls.Add($ADUserRateLabel,0,1)
$ADUpdateUserInformationPanel.Controls.Add($ADUserRateTextBox,1,1)
$ADUpdateUserInformationPanel.Controls.Add($ADUserOfficeLabel,0,2)
$ADUpdateUserInformationPanel.Controls.Add($ADUserOfficeTextBox,1,2)
$ADUpdateUserInformationPanel.Controls.Add($ADUserOfficeNumberLabel,2,2)
$ADUpdateUserInformationPanel.Controls.Add($ADUserOfficeNumberTextBox,3,2)
$ADUpdateUserInformationPanel.Controls.Add($ADUserPRDLabel,0,3)
$ADUpdateUserInformationPanel.Controls.Add($ADUserPRDTextBox,1,3)
$ADUpdateUserInformationPanel.Controls.Add($ADUserDescriptionLabel,0,4)
$ADUpdateUserInformationPanel.Controls.Add($ADUserDescriptionTextBox,1,4)
$ADUpdateUserInformationPanel.Controls.Add($SetUserInfoButton,4,1)
#endregion update user information panel

$MainTableLayoutPanel.Controls.Add($tableLayoutPanel2,0,0)
$MainTableLayoutPanel.Controls.Add($ExpiryTableLayoutPanel,1,2)
$MainTableLayoutPanel.Controls.Add($GroupControlsTableLayoutPanel,5,2)
$MainTableLayoutPanel.Controls.Add($ADUpdateUserInformationPanel,0,2)
$tableLayoutPanel2.Controls.Add($ADReportsTableLayoutPanel,2,0)
$tableLayoutPanel2.Controls.Add($OptionButtonsTableLayoutPanel,2,0)
$tableLayoutPanel2.Controls.Add($DomainServersTableLayoutPanel,0,4)
$GroupControlsTableLayoutPanel.Controls.Add($NTKAssignmentPanel,2,0)

$MainTableLayoutPanel.SetColumnSpan($tableLayoutPanel2,6)
$MainTableLayoutPanel.SetColumnSpan($ADUpdateUserInformationPanel,$MainTableLayoutPanel.ColumnCount)
$tableLayoutPanel2.SetColumnSpan($ADReportsTableLayoutPanel,3)
$tableLayoutPanel2.SetColumnSpan($OptionButtonsTableLayoutPanel,3)
$tableLayoutPanel2.SetColumnSpan($DomainServersTableLayoutPanel,6)
$tableLayoutPanel2.SetRowSpan($ADReportsTableLayoutPanel,5)
$tableLayoutPanel2.SetRowSpan($OptionButtonsTableLayoutPanel,$OptionButtonsRowSpan)
$GroupControlsTableLayoutPanel.SetRowSpan($NTKAssignmentPanel,7)
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
        Name = "ActiveDirectoryApplet"
        Text = "Account Viewer and Updater"
        FormBorderStyle = "FixedDialog"
        StartPosition = "CenterScreen"
        ClientSize = $System_Drawing_Size
        BackColor = "LightBlue"
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