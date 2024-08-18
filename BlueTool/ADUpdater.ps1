add-type -AssemblyName System.Windows.Forms
add-type -AssemblyName System.Drawing
# Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName PresentationFramework
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class ProcessDPI {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SetProcessDPIAware();
}
'@

$null = [ProcessDPI]::SetProcessDPIAware()

$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

$TitleFont = New-Object System.Drawing.Font("Calibri",24,[Drawing.FontStyle]::Bold)
$BodyFont = New-Object System.Drawing.Font("Calibri",18,[Drawing.FontStyle]::Bold)
$BoxFont = New-Object System.Drawing.Font("Calibri", 12, [Drawing.FontStyle]::Regular)
$BoldBoxFont = New-Object System.Drawing.Font("Calibri", 12, [Drawing.FontStyle]::Bold)

#region create the controls
$ADUserLabel = New-Object System.Windows.Forms.Label
$ADSearchTypeLabel = New-Object System.Windows.Forms.Label

$ADPrincipalTextBox = New-Object System.Windows.Forms.TextBox

$DisplayInfoBox = New-Object System.Windows.Forms.RichTextBox

$ADLookupButton = New-Object System.Windows.Forms.Button

$VulnIDBox = New-Object System.Windows.Forms.ListView

$SupportedSTIGSBox = New-Object System.Windows.Forms.ListBox

$AFKeys = New-Object System.Windows.Forms.ComboBox

$ADSearchUsersRadioButton = New-Object System.Windows.Forms.RadioButton
$ADSearchComputersRadioButton = New-Object System.Windows.Forms.RadioButton
#endregion

#region event handlers
$handler_ADLookupButton_Click = 
  {
    Write-Host $objPrincipal
    try {
        $principal = $ADPrincipalTextBox.Text
        if ($principal) { 
            $objPrincipal = switch ($true) {
                $ADSearchUsersRadioButton.Checked { Get-ADUser -Identity $principal -Properties *; break } 
                $ADSearchComputersRadioButton.Checked { Get-ADComputer -Identity $principal -Properties *; break }
            }

            if ([string]::IsNullOrWhiteSpace($objPrincipal)) {
                Write-Host "ERROR"
                [System.Windows.MessageBox]::Show("Unable to find $principal", "Active Directory Search Failed",`
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
            $DisplayInfoBox.Text = $objPrincipal | Out-String
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
    $ADUserLabel.Text = "Enter a computer name"
    $ADLookupButton.Text = "Lookup Computers"
}

$handler_ADSearchUsersRadioButton_Click = 
{
    Write-Host "Users Radio Button Pressed"
    $ADUserLabel.Text = "Enter a username"
    $ADLookupButton.Text = "Lookup Users"
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

#region Display text box
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = $ADLookupButton.Location.X
$System_Drawing_Point.Y = $ADLookupButton.Bottom + 20
$DisplayInfoBox.Location = $System_Drawing_Point
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = $form.ClientSize.Width-$DisplayInfoBox.Location.X * 2
$System_Drawing_Size.Height = $form.ClientSize.Height - $ADLookupButton.Bottom - 35
$DisplayInfoBox.Size = $System_Drawing_Size
$DisplayInfoBox.Name = "DisplayInfoBox"
$DisplayInfoBox.Multiline = $true
$DisplayInfoBox.Scrollbars = "Both"
$DisplayInfoBox.Readonly = $true
$DisplayInfoBox.Font = $BoxFont
$DisplayInfoBox.Font = [System.Drawing.Font]::new($BoxFont.FontFamily, $BoxFont.Size-2, $BoxFont.Style)
$form.Controls.Add($DisplayInfoBox)
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

#region computer search checkbox
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

$form.ResumeLayout()

# set control visibility on form load
$ADUserLabel.Visible = $true
$ADPrincipalTextBox.Visible = $true
$ADLookupButton.Visible = $true
$DisplayInfoBox.Visible = $true

#Init the OnLoad event to correct the initial state of the form
$InitialFormWindowState = $form.WindowState

$form.Add_FormClosed($handler_formclose)

#Show the Form
$form.ShowDialog()
# $null = [Windows.Forms.Application]::Run($form)