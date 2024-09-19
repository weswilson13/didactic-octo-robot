Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region Import App.config
Add-Type -AssemblyName System.Configuration

    # Set this to the full path of your App.config
    $configPath = "$PSScriptRoot\App.config"

    [System.AppDomain]::CurrentDomain.SetData("APP_CONFIG_FILE", $configPath)
    [Configuration.ConfigurationManager].GetField("s_initState", "NonPublic, Static").SetValue($null, 0)
    [Configuration.ConfigurationManager].GetField("s_configSystem", "NonPublic, Static").SetValue($null, $null)
    ([Configuration.ConfigurationManager].Assembly.GetTypes() | 
        Where-Object {$_.FullName -eq "System.Configuration.ClientConfigPaths"})[0].GetField("s_current", "NonPublic, Static").SetValue($null, $null)

    $AppSettings = [System.Configuration.ConfigurationManager]::AppSettings
    $ConnectionStrings = [System.Configuration.ConfigurationManager]::ConnectionStrings
#endregion import App.config

$consolasFontRegular = [System.Drawing.Font]::new('Consolas', 10, [Drawing.FontStyle]::Regular)
$consolasFontBold = [System.Drawing.Font]::new('Consolas', 10, [Drawing.FontStyle]::Bold)

$label = New-Object System.Windows.Forms.Label
$label.Dock = "Fill"
$label.Text = "Choose a certificate template:"
$label.Font = $consolasFontBold
$label.AutoSize = $true

$webServerRadioButton = New-Object System.Windows.Forms.RadioButton
$webServerRadioButton.Checked = $true
$webServerRadioButton.Text = "WebServer"
$webServerRadioButton.Font = $consolasFontRegular
$webServerRadioButton.AutoSize = $true
$webServerRadioButton.Anchor = [System.Windows.Forms.AnchorStyles]::Left
$webServerRadioButton.Dock = 'None'

$printerRadioButton = New-Object System.Windows.Forms.RadioButton
$printerRadioButton.Checked = $false
$printerRadioButton.Text = "Printer"
$printerRadioButton.Font = $consolasFontRegular
$printerRadioButton.AutoSize = $true
$printerRadioButton.Anchor = [System.Windows.Forms.AnchorStyles]::Left
$printerRadioButton.Dock = 'None'

$otherRadioButton = New-Object System.Windows.Forms.RadioButton
$otherRadioButton.Checked = $false
$otherRadioButton.Text = "Other"
$otherRadioButton.Font = $consolasFontRegular
$otherRadioButton.AutoSize = $true
$otherRadioButton.Anchor = [System.Windows.Forms.AnchorStyles]::Left
$otherRadioButton.Dock = 'None'

$radioButtonPanel = New-Object System.Windows.Forms.TableLayoutPanel
$radioButtonPanel.ColumnCount = 1
$radioButtonPanel.RowCount = 4
$radioButtonPanel.Dock = 'Fill'
$radioButtonPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$radioButtonPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 28))) | Out-Null
$radioButtonPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 28))) | Out-Null
$radioButtonPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 28))) | Out-Null
$radioButtonPanel.Controls.AddRange(@($label,$webServerRadioButton, $printerRadioButton, $otherRadioButton))

$button = New-Object System.Windows.Forms.Button
$button.Text = "Request Certificate"
$button.AutoSize = $true
$button.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$button.Dock = 'None'
$button.Add_Click({
    $params = @("-NoExit -File `"$($AppSettings["GenerateCertificateScriptPath"])`"")

    if ($webServerRadioButton.Checked) {
        $params += "-Template WebServer"
    }
    elseif ($printerRadioButton.Checked) {
        $params += "-Template Printer"
    }
    elseif ($otherRadioButton.Checked) {
        # TO DO
        $params += "-Template Other"
    }

    # $contents = $textbox.Text.Split([string[]]@(',',' ',';',"`r`n"), [System.StringSplitOptions]::RemoveEmptyEntries + [System.StringSplitOptions]::TrimEntries )
    # $fqdn = @()
    # foreach ($line in $contents) {
    #     $fqdn += $line
    # }

    $params += "-AssetName $($textBox.Text)"
    $proc = Start-Process powershell.exe -ArgumentList $params -Wait -PassThru
    $proc.WaitForExit()

    if ($proc.ExitCode -eq 0) { $textBox.Clear() }
})

$defaultText = "Enter the device FQDN"
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Text = $defaultText
$textBox.Font = $consolasFontRegular
$textBox.Width = 200
$textbox.Multiline = $false
$textbox.Dock = "None"
$textBox.Add_Click({
    if ($this.Text -eq $defaultText) {
        $this.ResetText()
    }
})
$textbox.AutoCompleteSource = [System.Windows.Forms.AutoCompleteSource]::CustomSource
$textBox.AutoCompleteMode = 'SuggestAppend'
$customSource = New-Object System.Windows.Forms.AutoCompleteStringCollection

# TO DO textbox custom source
if ($webServerRadioButton.Checked) {
    [ADSI]$serversOU = "LDAP://OU=Windows2019,OU=Homelab,DC=mydomain,DC=local"
    $customSource.AddRange($serversOU.Children.dNSHostName)
}
elseif ($printerRadioButton) {
    [ADSI]$printersOU = "LDAP://OU=Windows2019,OU=Homelab,DC=mydomain,DC=local"
    $customSource.AddRange($printersOU.Children.dNSHostName)
}
elseif ($otherRadioButton) {
    [ADSI]$otherOU = "LDAP://OU=Windows2019,OU=Homelab,DC=mydomain,DC=local"
    $customSource.AddRange($otherOU.Children.dNSHostName)
}
$textBox.AutoCompleteCustomSource = $customSource

$tableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel.RowCount = 3
$tableLayoutPanel.ColumnCount = 1
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 60))) | Out-Null
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel.RowStyles.Add((new-object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
$tableLayoutPanel.Dock = "Fill"
# $tableLayoutPanel.CellBorderStyle = "outset"
$tableLayoutPanel.Controls.Add($radioButtonPanel,0,0)
$tableLayoutPanel.Controls.Add($textBox,0,1)
$tableLayoutPanel.Controls.Add($button,0,2)

$form = New-Object System.Windows.Forms.Form
$form.Text = "Request New Certificates"
$form.ClientSize = New-Object System.Drawing.Size(300,200)
$formsize = $form.Size
$form.MinimumSize = $formsize
$form.MaximumSize = $formsize
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Add_FormClosed({
    $form.Close()
    $form.Dispose()
})

$form.Controls.AddRange(@($tableLayoutPanel))
$form.ShowDialog()

