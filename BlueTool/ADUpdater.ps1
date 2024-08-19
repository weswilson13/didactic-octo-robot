function Reset-Form {
    param(
        [switch]$ExceptPrincipal
    )
    if (!$ExceptPrincipal.IsPresent) { $ADPrincipalTextBox.ResetText() }
    $ADGetGroupMembershipButton.Visible = $false
    $UpdateGroupMembershipsButton.Visible = $false
    $ADGroupsBox.Visible = $false
    $ADGroupMembershipBox.Visible = $false
    $DisplayInfoBox.ResetText()
    $DisplayInfoBox.Visible = $true
    $ADGroupsBox.Items.Clear()
    $ADGroupMembershipBox.Items.Clear()
    $ADAccountStatusLabel.Visible = $false
    $ADAccountExpirationLabel.Visible = $false
    $ADAccountEnableLabel.Visible = $false
    $ADAccountUnlockLabel.Visible = $false
    $ADAccountEnableButton.Visible = $false
    $ADAccountRequiresSmartcardLabel.Visible = $false
    $ADAccountRequiresSmartcardCheckBox.Visible = $false
    $ADAccountActionsLabel.Visible = $false
    $ADAccountExpiryDatePicker.Visible = $false
}

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

#region font objects
$TitleFont = New-Object System.Drawing.Font("Calibri",24,[Drawing.FontStyle]::Bold)
$BodyFont = New-Object System.Drawing.Font("Calibri",18,[Drawing.FontStyle]::Bold)
$BoxFont = New-Object System.Drawing.Font("Calibri", 12, [Drawing.FontStyle]::Regular)
$BoldBoxFont = New-Object System.Drawing.Font("Calibri", 12, [Drawing.FontStyle]::Bold)
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

# List views
# $VulnIDBox = New-Object System.Windows.Forms.ListView

# ListBoxes
$ADGroupsBox = New-Object System.Windows.Forms.ListBox
$ADGroupMembershipBox = New-Object System.Windows.Forms.ListBox

# Datepicker
$ADAccountExpiryDatePicker = New-Object System.Windows.Forms.DateTimePicker

# ComboBoxes
# $AFKeys = New-Object System.Windows.Forms.ComboBox

# RadioButtons
$ADSearchUsersRadioButton = New-Object System.Windows.Forms.RadioButton
$ADSearchComputersRadioButton = New-Object System.Windows.Forms.RadioButton
$ADSearchServiceAccountsRadioButton = New-Object System.Windows.Forms.RadioButton

# Checkboxes
$ADAccountRequiresSmartcardCheckBox = New-Object System.Windows.Forms.CheckBox

#endregion

#region event handlers
$handler_ADLookupButton_Click = 
  {
    # reset the form
    Reset-Form -ExceptPrincipal

    try {
        $principal = $ADPrincipalTextBox.Text
        if ($principal) { 
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

            # set control values that depend on the AD Object
            $ADAccountEnableLabel.Text = "Account Enabled: $($objPrincipal.Enabled)"
            $ADAccountExpirationLabel.Text = "Account Expiration Date: $($objPrincipal.AccountExpirationDate)"
            $ADAccountExpiryDatePicker.Value = switch($objPrincipal.AccountExpirationDate) {
                $null { $ADAccountExpiryDatePicker.MaxDate;break }
                default { $PSItem }
            } 
            $ADAccountRequiresSmartcardCheckBox.Checked = $objPrincipal.SmartcardLogonRequired
            $ADAccountUnlockLabel.Text = "Account Locked Out: $($objPrincipal.LockedOut)"

            $ADGetGroupMembershipButton.Visible=$true

            if ($objPrincipal.ObjectClass -eq 'user') {
                $ADAccountStatusLabel.Visible = $true
                $ADAccountExpirationLabel.Visible = $true
                $ADAccountEnableLabel.Visible = $true
                $ADAccountUnlockLabel.Visible = $true
                $ADAccountRequiresSmartcardLabel.Visible = $true
                $ADAccountActionsLabel.Visible = $true
                $ADAccountEnableButton.Visible = $true
                $ADAccountRequiresSmartcardCheckBox.Visible = $true
                $ADAccountExpiryDatePicker.Visible = $true
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
    if ($objPrincipal) {
        $DisplayInfoBox.Visible=$false
        $ADGroupsBox.Visible = $true
        $ADGroupMembershipBox.Visible = $true
        Get-ADGroup -Filter 'GroupScope -ne "DomainLocal"' | 
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
        # remove groups
        $objPrincipal.MemberOf.Where({ $_ -notin $ADGroupMembershipBox.Items }) | ForEach-Object {
            Get-ADGroup $PSItem | Remove-ADGroupMember -Members $objPrincipal -Confirm:$false
        }
        
        # add groups
        $ADGroupMembershipBox.Items.Where({ $_ -notin $objPrincipal.MemberOf }) | ForEach-Object {
            Get-ADGroup $PSItem | Add-ADGroupMember -Members $objPrincipal -Confirm:$false
        }
        
        [System.Windows.MessageBox]::Show("Finished updating group membership", "Group Membership Update Success",`
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
        $currentState = $objPrincipal.Enabled
        switch ($currentState) {
            $true { Disable-ADAccount $objPrincipal -Confirm:$false;break }
            $false { Enable-ADAccount $objPrincipal -Confirm:$false;break }
        }

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

$handler_formclose =
  {
    # if (($SaveButton.Enabled -eq $True) -and ($SaveButton.Visible -eq $True)){
    #   $confirm = [System.Windows.MessageBox]::Show("$AFFilePath is not saved. Save and Exit?", "Confirmation", "YesNo", "Question")
  
    #   if ($confirm -eq "Yes") {
    #     &$handler_SaveButton_Click
    #   }
    # }
  
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
$ADUserLabel.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 15
$System_Drawing_Point.Y = 15
$ADUserLabel.Location = $System_Drawing_Point
$form.Controls.Add($ADUserLabel)
#endregion

#region Username input textbox
$ADPrincipalTextBox.Width = 150 # $form.Width * 0.3
$ADPrincipalTextBox.Height = 15
$ADPrincipalTextBox.Name = "ADUserInput"
$ADPrincipalTextBox.Multiline = $false
$ADPrincipalTextBox.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADUserLabel.Location.X 
$System_Drawing_Point.Y = $ADUserLabel.Bottom + 5
$ADPrincipalTextBox.Location = $System_Drawing_Point
$form.Controls.Add($ADPrincipalTextBox)
#endregion

#region Lookup User Button
$ADLookupButton.Name = "ADLookupButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$ADLookupButton.AutoSize = $true
$ADLookupButton.AutoSizeMode = "GrowAndShrink"
$ADLookupButton.UseVisualStyleBackColor = $True
$ADLookupButton.Text = "Lookup User"
$ADLookupButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADPrincipalTextBox.Location.X
$System_Drawing_Point.Y = $ADPrincipalTextBox.Bottom + 10
$ADLookupButton.Location = $System_Drawing_Point
$ADLookupButton.add_Click($handler_ADLookupButton_Click)
$form.Controls.Add($ADLookupButton)
#endregion

#region search type label
$ADSearchTypeLabel.Text = "Search Type"
$ADSearchTypeLabel.AutoSize = $true
$ADSearchTypeLabel.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADPrincipalTextBox.Right + 30
$System_Drawing_Point.Y = $ADUserLabel.Top
$ADSearchTypeLabel.Location = $System_Drawing_Point
$form.Controls.Add($ADSearchTypeLabel)
#endregion

#region user search radiobutton
$ADSearchUsersRadioButton.Name = "ADUserSearchUsersRadioButton"
$ADSearchUsersRadioButton.Text = "Users"
$ADSearchUsersRadioButton.Font = $BoxFont
$ADSearchUsersRadioButton.Checked = $true
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADSearchTypeLabel.Left + 10
$System_Drawing_Point.Y = $ADPrincipalTextBox.Top
$ADSearchUsersRadioButton.Location = $System_Drawing_Point
$ADSearchUsersRadioButton.UseVisualStyleBackColor = $True
$ADSearchUsersRadioButton.add_Click($handler_ADSearchUsersRadioButton_Click)
$form.Controls.Add($ADSearchUsersRadioButton)
#endregion

#region computer search radiobutton
$ADSearchComputersRadioButton.Name = "ADUserSearchComputersRadioButton"
$ADSearchComputersRadioButton.Text = "Computers"
$ADSearchComputersRadioButton.Font = $BoxFont
$ADSearchComputersRadioButton.Checked = $false
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADSearchUsersRadioButton.Left
$System_Drawing_Point.Y = $ADSearchUsersRadioButton.Bottom
$ADSearchComputersRadioButton.Location = $System_Drawing_Point
$ADSearchComputersRadioButton.UseVisualStyleBackColor = $True
$ADSearchComputersRadioButton.add_Click($handler_ADSearchComputersRadioButton_Click)
$form.Controls.Add($ADSearchComputersRadioButton)
#endregion

#region service account search radiobutton
$ADSearchServiceAccountsRadioButton.Name = "ADUserSearchServiceAccountsRadioButton"
$ADSearchServiceAccountsRadioButton.Text = "Service Accounts"
$ADSearchServiceAccountsRadioButton.Font = $BoxFont
$ADSearchServiceAccountsRadioButton.AutoSize = $true
$ADSearchServiceAccountsRadioButton.Checked = $false
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADSearchUsersRadioButton.Left
$System_Drawing_Point.Y = $ADSearchComputersRadioButton.Bottom
$ADSearchServiceAccountsRadioButton.Location = $System_Drawing_Point
$ADSearchServiceAccountsRadioButton.UseVisualStyleBackColor = $True
$ADSearchServiceAccountsRadioButton.add_Click($handler_ADSearchServiceAccountsRadioButton_Click)
$form.Controls.Add($ADSearchServiceAccountsRadioButton)
#endregion

#region Account Status Label
$ADAccountStatusLabel.Name = "ADAccountStatusLabel"
$ADAccountStatusLabel.Text = "Account Status"
$ADAccountStatusLabel.Font = $BoldBoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADSearchServiceAccountsRadioButton.Location.X + $ADSearchServiceAccountsRadioButton.PreferredSize.Width + 50
$System_Drawing_Point.Y = $ADUserLabel.Top
$ADAccountStatusLabel.Location = $System_Drawing_Point
$ADAccountStatusLabel.AutoSize = $true
$form.Controls.Add($ADAccountStatusLabel)
#endregion

#region Account Expiration Label
$ADAccountExpirationLabel.Name = "ADAccountExpirationLabel"
$ADAccountExpirationLabel.Text = "Account Expiration Date: $($objPrincipal.AccountExpirationDate)"
$ADAccountExpirationLabel.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADAccountStatusLabel.Location.X
$System_Drawing_Point.Y = $ADAccountStatusLabel.Bottom
$ADAccountExpirationLabel.Location = $System_Drawing_Point
$ADAccountExpirationLabel.AutoSize = $true
$form.Controls.Add($ADAccountExpirationLabel)
#endregion

#region Account Enabled Label
$ADAccountEnableLabel.Name = "ADAccountEnabledLabel"
$ADAccountEnableLabel.Text = "Account Enabled: $($objPrincipal.Enabled)"
$ADAccountEnableLabel.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADAccountStatusLabel.Location.X
$System_Drawing_Point.Y = $ADAccountExpirationLabel.Bottom
$ADAccountEnableLabel.Location = $System_Drawing_Point
$ADAccountEnableLabel.AutoSize = $true
$form.Controls.Add($ADAccountEnableLabel)
#endregion

#region Account Locked Label
$ADAccountUnlockLabel.Name = "ADAccountUnlockedLabel"
$ADAccountUnlockLabel.Text = "Account Locked Out: $($objPrincipal.LockedOut)"
$ADAccountUnlockLabel.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADAccountStatusLabel.Location.X
$System_Drawing_Point.Y = $ADAccountEnableLabel.Bottom
$ADAccountUnlockLabel.Location = $System_Drawing_Point
$ADAccountUnlockLabel.AutoSize = $true
$form.Controls.Add($ADAccountUnlockLabel)
#endregion

#region smartcard logon required Label
$ADAccountRequiresSmartcardLabel.Name = "ADAccountSmartcardRequiredLabel"
$ADAccountRequiresSmartcardLabel.Text = "Smartcard Required: $($objPrincipal.SmartcardLogonRequired)"
$ADAccountRequiresSmartcardLabel.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADAccountStatusLabel.Location.X
$System_Drawing_Point.Y = $ADAccountUnlockLabel.Bottom
$ADAccountRequiresSmartcardLabel.Location = $System_Drawing_Point
$ADAccountRequiresSmartcardLabel.AutoSize = $true
$form.Controls.Add($ADAccountRequiresSmartcardLabel)
#endregion

#region Display text box
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADLookupButton.Location.X
$System_Drawing_Point.Y = $ADAccountRequiresSmartcardLabel.Bottom + 20
$DisplayInfoBox.Location = $System_Drawing_Point
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = $form.ClientSize.Width-$DisplayInfoBox.Location.X * 2
$System_Drawing_Size.Height = $form.ClientSize.Height - ($ADAccountRequiresSmartcardLabel.Location.Y + $ADAccountRequiresSmartcardLabel.PreferredSize.Height) - 35
$DisplayInfoBox.Size = $System_Drawing_Size
$DisplayInfoBox.Name = "DisplayInfoBox"
$DisplayInfoBox.Multiline = $true
$DisplayInfoBox.Scrollbars = "Both"
$DisplayInfoBox.Readonly = $true
$DisplayInfoBox.Font = $BoxFont
$DisplayInfoBox.Font = [System.Drawing.Font]::new($BoxFont.FontFamily, $BoxFont.Size-2, $BoxFont.Style)
$form.Controls.Add($DisplayInfoBox)
#endregion

#region account actions label
$ADAccountActionsLabel.Name = "ADAccountActionsLabel"
$ADAccountActionsLabel.Text = "Account Actions"
$ADAccountActionsLabel.Font = $BoxFont
$ADAccountActionsLabel.AutoSize = $true
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADAccountRequiresSmartcardLabel.Location.X + $ADAccountRequiresSmartcardLabel.PreferredWidth + 50
$System_Drawing_Point.Y = $ADAccountStatusLabel.Top
$ADAccountActionsLabel.Location = $System_Drawing_Point
$form.Controls.Add($ADAccountActionsLabel)
#endregion

#region Account expiry datepicker
$ADAccountExpiryDatePicker.Name = "ADAccountExpiryDatePicker"
$ADAccountExpiryDatePicker.Value = switch ($objPrincipal.AccountExpirationDate) {
    $null { $ADAccountExpiryDatePicker.MaxDate;break }
    default { $PSItem }
}
$ADAccountExpiryDatePicker.AutoSize = $true
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADAccountActionsLabel.Location.X
$System_Drawing_Point.Y = $ADAccountActionsLabel.Location.Y + $ADAccountActionsLabel.PreferredHeight
$ADAccountExpiryDatePicker.Location = $System_Drawing_Point
$form.Controls.Add($ADAccountExpiryDatePicker)
#endregion

#region Enable/Disable Account button
$ADAccountEnableButton.Name = "ADAccountEnableButton"
$ADAccountEnableButton.Text = switch ($objPrincipal.Enabled) {
    $true { "Disable Account";break }
    $false { "Enable Account";break }
}
$ADAccountEnableButton.Font = $BoxFont
$ADAccountEnableButton.AutoSize = $true
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADAccountActionsLabel.Location.X
$System_Drawing_Point.Y = $ADAccountExpiryDatePicker.Location.Y + $ADAccountExpiryDatePicker.PreferredSize.Height + 2
$ADAccountEnableButton.Location = $System_Drawing_Point
$ADAccountEnableButton.add_Click($handler_ADAccountEnableButton_Click)
$form.Controls.Add($ADAccountEnableButton)
#endregion

#region Account requires smartcard checkbox
$ADAccountRequiresSmartcardCheckBox.Name = "ADAccountRequiresSmartcard"
$ADAccountRequiresSmartcardCheckBox.Text = "SmartcardLogonRequired"
$ADAccountRequiresSmartcardCheckBox.AutoSize = $true
$ADAccountRequiresSmartcardCheckBox.Font = $BoxFont
$ADAccountRequiresSmartcardCheckBox.Checked = $objPrincipal.SmartcardLogonRequired
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADAccountActionsLabel.Location.X
$System_Drawing_Point.Y = $ADAccountEnableButton.Location.Y + $ADAccountEnableButton.PreferredSize.Height + 2
$ADAccountRequiresSmartcardCheckBox.Location = $System_Drawing_Point
$ADAccountRequiresSmartcardCheckBox.UseVisualStyleBackColor = $True
$ADAccountRequiresSmartcardCheckBox.add_Click($handler_ADAccountRequiresSmartCardCheckbox_Click)
$form.Controls.Add($ADAccountRequiresSmartcardCheckBox)
#endregion

#region Enumerate group memberships Button
$ADGetGroupMembershipButton.Name = "ADGetGroupMembershipButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$ADGetGroupMembershipButton.AutoSize = $true
$ADGetGroupMembershipButton.UseVisualStyleBackColor = $True
$ADGetGroupMembershipButton.Text = "Get Group Membership"
$ADGetGroupMembershipButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADAccountActionsLabel.Location.X
$System_Drawing_Point.Y = $ADAccountRequiresSmartcardCheckBox.Bottom
$ADGetGroupMembershipButton.Location = $System_Drawing_Point
$ADGetGroupMembershipButton.add_Click($handler_ADGetGroupMembershipButton_Click)
$form.Controls.Add($ADGetGroupMembershipButton)
#endregion

#region AD Groups List box
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADLookupButton.Location.X
$System_Drawing_Point.Y = $ADLookupButton.Bottom + 20
$ADGroupsBox.Location = $System_Drawing_Point
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 200
$System_Drawing_Size.Height = $form.ClientSize.Height - $ADLookupButton.Bottom - 35
$ADGroupsBox.Size = $System_Drawing_Size
$ADGroupsBox.SelectionMode = "MultiExtended"
$ADGroupsBox.Name = "ADGroupsBox"
$ADGroupsBox.Font = $BoxFont
$form.Controls.Add($ADGroupsBox)
#endregion

#region RemoveGroups button
$RemoveGroupButton.Font = $BoxFont
$RemoveGroupButton.Name = "RemoveGroupButton"
$RemoveGroupButton.Text = "<-"
$RemoveGroupButton.AutoSize = $true
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADGroupsBox.Right + 10
$System_Drawing_Point.Y = $ADGroupsBox.Top + ($ADGroupsBox.Height - $RemoveGroupButton.Height)/2
$RemoveGroupButton.Location = $System_Drawing_Point
$RemoveGroupButton.add_Click($handler_RemoveGroupButton_Click)
$form.Controls.Add($RemoveGroupButton)
#endregion

#region AddGroups button
$AddGroupButton.Font = $BoxFont
$AddGroupButton.Name = "AddGroupButton"
$AddGroupButton.Text = "->"
$AddGroupButton.AutoSize = $true
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $RemoveGroupButton.Right + 5
$System_Drawing_Point.Y = $RemoveGroupButton.Top
$AddGroupButton.Location = $System_Drawing_Point
$AddGroupButton.add_Click($handler_AddGroupButton_Click)
$form.Controls.Add($AddGroupButton)
#endregion

#region AD Group Membership List box
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $AddGroupButton.Right + 10
$System_Drawing_Point.Y = $ADLookupButton.Bottom + 20
$ADGroupMembershipBox.Location = $System_Drawing_Point
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 200
$System_Drawing_Size.Height = $form.ClientSize.Height - $ADLookupButton.Bottom - 35
$ADGroupMembershipBox.Size = $System_Drawing_Size
$ADGroupMembershipBox.SelectionMode = "MultiExtended"
$ADGroupMembershipBox.Name = "ADGroupMembershipBox"
$ADGroupMembershipBox.Font = $BoxFont
$form.Controls.Add($ADGroupMembershipBox)
#endregion

#region Update group memberships Button
$UpdateGroupMembershipsButton.Name = "UpdateGroupMembershipsButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$UpdateGroupMembershipsButton.AutoSize = $true
$UpdateGroupMembershipsButton.UseVisualStyleBackColor = $True
$UpdateGroupMembershipsButton.Text = "Update Group Membership"
$UpdateGroupMembershipsButton.Font = $BoxFont
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADSearchUsersRadioButton.Right + 30
$System_Drawing_Point.Y = $ADSearchUsersRadioButton.Top
$UpdateGroupMembershipsButton.Location = $System_Drawing_Point
$UpdateGroupMembershipsButton.add_Click($handler_UpdateGroupMembershipButton_Click)
$form.Controls.Add($UpdateGroupMembershipsButton)
#endregion
#endregion

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