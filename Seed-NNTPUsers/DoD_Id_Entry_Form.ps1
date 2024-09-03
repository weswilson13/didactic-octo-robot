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

$form = New-Object System.Windows.Forms.Form
$form.Text = "Enter DoD IDs"
$form.ClientSize = New-Object System.Drawing.Size(400,400)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Add_FormClosed({
    $form.Close()
    $form.Dispose()
})

$form.Controls.AddRange(@($button, $textBox))
$form.ShowDialog()
