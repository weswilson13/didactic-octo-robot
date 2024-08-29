# Load external assemblies
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$ini = Get-IniContent $PSScriptRoot\config.ini
#
# MS_Main
#
$objParams = @{
    TypeName = 'System.Windows.Forms.MenuStrip'
    Property = @{
        Location = new-object System.Drawing.Point(0, 0)
        Name = "MS_Main"
        Size = new-object System.Drawing.Size(354, 24)
        TabIndex = 0
        Text = "menuStrip1"
    }
}
$MS_Main = New-Object @objParams

#
# fileToolStripMenuItem
#
$objParams = @{
    TypeName = 'System.Windows.Forms.ToolStripMenuItem'
    Property = @{
        Name = "fileToolStripMenuItem"
        Size = new-object System.Drawing.Size(35, 20)
        Text = "&File"
    }
}
$fileToolStripMenuItem = New-Object @objParams

#
# openConfigToolStripMenuItem
#
$objParams = @{
    TypeName = 'System.Windows.Forms.ToolStripMenuItem'
    Property = @{
        Name = "openConfigToolStripMenuItem"
        Size = new-object System.Drawing.Size(152, 22)
        Text = "&Open Config.ini"
    }
}
$openConfigToolStripMenuItem = New-Object @objParams

$fileToolStripMenuItem.DropDownItems.AddRange(@($openConfigToolStripMenuItem))

function OnClick_openConfigToolStripMenuItem($Sender,$e){
   & "C:\Program Files\Notepad++\notepad++.exe" $PSScriptRoot\config.ini
}

$openConfigToolStripMenuItem.Add_Click( { OnClick_openConfigToolStripMenuItem $openToolStripMenuItem $EventArgs} )
#
# optionsToolStripMenuItem
#
$objParams = @{
    TypeName = 'System.Windows.Forms.ToolStripMenuItem'
    Property = @{
        Name = "optionsToolStripMenuItem"
        Size = new-object System.Drawing.Size(51, 20)
        Text = "&Options"
    }
}
$optionsToolStripMenuItem = New-Object @objParams

#
# showConnToolStripMenuItem
#
$objParams = @{
    TypeName = 'System.Windows.Forms.ToolStripMenuItem'
    Property = @{
        Name = "showConnToolStripMenuItem"
        Size = new-object System.Drawing.Size(152, 22)
        Text = "&Show Connection Info"
    }
}
$showConnToolStripMenuItem = New-Object @objParams
function handler_showConnToolStripMenuItem_Clicked {
    $loggerConfig = @("Logger Connection",
        $ini.LoggerConfig.SqlServerInstance,
        $ini.LoggerConfig.Database,
        $ini.LoggerConfig.Schema,
        $ini.LoggerConfig.Table)
    $loggerConnection = ("{0}: {1}.{2}.{3}.{4}" -f $loggerConfig)

    $NotepadDbConfig = @("NOTEPAD Connection",
        $ini.NotepadDbConfig.SqlServerInstance,
        $ini.NotepadDbConfig.Database,
        $ini.NotepadDbConfig.Schema,
        $ini.NotepadDbConfig.Table)
    $NotepadConnection = ("{0}: {1}.{2}.{3}.{4}" -f $NotepadDbConfig)

    [void][System.Windows.Forms.MessageBox]::Show("$loggerConnection`n$NotepadConnection")
}

$showConnToolStripMenuItem.add_Click({handler_showConnToolStripMenuItem_Clicked})

$optionsToolStripMenuItem.DropDownItems.AddRange(@($showConnToolStripMenuItem))

$MS_Main.Items.AddRange(@(
    $fileToolStripMenuItem,
    $optionsToolStripMenuItem))

#
$MenuForm = new-object System.Windows.Forms.form
#
$MenuForm.ClientSize = new-object System.Drawing.Size(354, 141)
$MenuForm.Controls.Add($MS_Main)
$MenuForm.MainMenuStrip = $MS_Main
$MenuForm.Name = "MenuForm"
$MenuForm.Text = "I\'ve got a menu"
function OnFormClosing_MenuForm($Sender,$e){ 
    # $this represent sender (object)
    # $_ represent  e (eventarg)

    # Allow closing
    ($_).Cancel= $False
}
$MenuForm.Add_FormClosing( { OnFormClosing_MenuForm $MenuForm $EventArgs} )
$MenuForm.Add_Shown({$MenuForm.Activate()})
$MenuForm.ShowDialog()
#Free ressources
$MenuForm.Dispose()