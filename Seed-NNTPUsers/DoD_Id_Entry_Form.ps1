Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$button = New-Object System.Windows.Forms.Button
$button.Text = "Enumerate Contents"
$button.AutoSize = $true
$button.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$button.Dock = 'Bottom'
$button.Add_Click({
    $contents = ($textbox.Text.Split(',')).Split(' ')
    $dodIds = @()
    foreach ($line in $contents) {
        $dodIds += $line
    }
    $textBox.Clear()
    & "$PSScriptRoot\Get-TSCRUsers.ps1" -DODID $dodIDs
})

$defaultText = "Enter one or more DoD IDs separated by commas..."
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Text = $defaultText
$textbox.Multiline = $true
$textbox.Dock = "Fill"
$textBox.Add_Click({
    if ($this.Text -eq $defaultText) {
        $this.ResetText()
    }
})

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
$tableLayoutPanel.Controls.Add($textBox,0,1)
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