[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [System.IO.FileInfo]$ScriptPath,    

    [Parameter(Mandatory=$false)]
    [switch]$GetSoftware
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Configuration

# Set this to the full path of your App.config
$configPath = "$PSScriptRoot\App.config"

[System.AppDomain]::CurrentDomain.SetData("APP_CONFIG_FILE", $configPath)
[Configuration.ConfigurationManager].GetField("s_initState", "NonPublic, Static").SetValue($null, 0)
[Configuration.ConfigurationManager].GetField("s_configSystem", "NonPublic, Static").SetValue($null, $null)
([Configuration.ConfigurationManager].Assembly.GetTypes() | 
    Where-Object {$_.FullName -eq "System.Configuration.ClientConfigPaths"})[0].GetField("s_current", "NonPublic, Static").SetValue($null, $null)

$AppSettings=[System.Configuration.ConfigurationManager]::AppSettings

$button = New-Object System.Windows.Forms.Button
$button.Text = "Execute"
$button.AutoSize = $true
$button.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$button.Dock = 'Bottom'
$button.Add_Click({
    $params = @{ComputerName = $computers}
    if ($GetSoftware.IsPresent) {
        $params["Software"] = $softwareTextBox.Text
    }
    $computers = $textbox.Text.Split([string[]]@(',',';',' ',"`r`n"),[System.StringSplitOptions]::RemoveEmptyEntries + [System.StringSplitOptions]::TrimEntries)
    $textBox.Clear()
    Write-Host $ScriptPath
    $params | Out-String | Write-Host
    & $ScriptPath @params
})

$defaultText = "Enter one or more computers separated by commas..."
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Text = $defaultText
$textbox.Multiline = $true
$textbox.Dock = "Fill"
$textBox.Add_Click({
    if ($this.Text -eq $defaultText) {
        $this.ResetText()
    }
})

[System.Collections.Arraylist]$textBoxes = @($textBox)

$softwareLabel = New-Object System.Windows.Forms.Label
$softwareLabel.Text = "Software:"
$softwareLabel.Font = New-Object System.Drawing.Font ("Calibri",12,[System.Drawing.FontStyle]::Regular)

$softwareTextBox = New-Object System.Windows.Forms.TextBox
$softwareTextBox.Text = [string]::Empty
$softwareTextbox.Multiline = $false
$softwareTextbox.Dock = "Fill"

# if ($GetSoftware.IsPresent) {$textBoxes.Add($softwareTextBox)}

$textBoxPanel = New-Object System.Windows.Forms.TableLayoutPanel
$textBoxPanel.ColumnCount = 2
$textBoxPanel.RowCount = 2
$textBoxPanel.Dock = "Fill"
$textBoxPanel.AutoSize = $true
$textBoxPanel.Controls.Add($textBox,0,0)
if ($GetSoftware.IsPresent) {
    $textBoxPanel.Controls.Add($softwareLabel,0,1)
    $textBoxPanel.Controls.Add($softwareTextBox,1,1)
}
$textBoxPanel.SetColumnSpan($textBox,2)
# $textBoxPanel.Controls.Add($softwareTextBox)

$textBoxPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 90))) | Out-Null
$textBoxPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 10))) | Out-Null

$label = New-Object System.Windows.Forms.Label
$label.Dock = "Fill"
# $label.Text = "Enter DoD IDs Below"
# $label.Font = New-Object System.Drawing.Font("Calibri",12,[Drawing.FontStyle]::Bold)
# $label.AutoSize = $true
$label.Add_Click({
    if ([string]::IsNullOrWhiteSpace($textBox.Text)) { $textBox.Text = $defaultText }
})

$tableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel.RowCount = 3
$tableLayoutPanel.ColumnCount = 1
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 5))) | Out-Null
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 85))) | Out-Null
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 10))) | Out-Null
$tableLayoutPanel.Dock = "Fill"
# $tableLayoutPanel.CellBorderStyle = "outset"
$tableLayoutPanel.Controls.Add($label,0,0)
$tableLayoutPanel.Controls.Add($textBoxPanel,0,1)
$tableLayoutPanel.Controls.Add($button,0,2)

$form = New-Object System.Windows.Forms.Form
$form.Text = "Enter DoD IDs"
$form.ClientSize = New-Object System.Drawing.Size(400,400)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Add_FormClosed({
    $form.Close()
    $form.Dispose()
})

$form.Controls.AddRange(@($tableLayoutPanel))
$form.ShowDialog()
