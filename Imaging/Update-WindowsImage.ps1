<#
    .SYNOPSIS 
    Steps to update an offline image and repackage as iso

    .COMPONENT
    Windows Assessment and Deployment Kit (ADK)
#>
[CmdletBinding()]
Param(
    # Path to Offline Image Files
    [Parameter(Mandatory=$true)]
    [System.IO.FileInfo]        
    $Source,

    # Disk label
    [Parameter(Mandatory=$true)]
    [string]
    $DiskLabel,

    # Path to final ISO
    [Parameter(Mandatory=$true)]
    [string]
    $Target,

    # Use powershell cmdlets
    [Parameter(Mandatory=$false)]
    [switch]
    $UsePowershell
)

function Use-RunAs {    
    # Check if script is running as Administrator and if not elevate it
    # Use Check Switch to check if admin 
     
    param([Switch]$Check) 
     
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()` 
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 
         
    if ($Check) { return $IsAdmin }   
      
    if ($MyInvocation.ScriptName -ne "") 
    {  
        if (-not $IsAdmin)  
          {  
            try 
            {   
                $params = @()
                foreach ($param in $_psBoundParameters.GetEnumerator()) {
                    switch ($param.Key) {
                        'UsePowershell' { [array]$params += "{0}" -f $param.Key; break }
                        default { [array]$params += "{0} `"{1}`"" -f $param.Key,$param.Value }
                    }
                }

                $params = ($params -join ' -')

                $arg = "-file `"$($MyInvocation.ScriptName)`" -$params"
                write-host $arg
                Pause
                Start-Process "powershell.exe" -Verb Runas -ArgumentList "-NoExit $arg" -ErrorAction 'stop'  
            } 
            catch 
            { 
                Write-Warning "Error - Failed to restart script elevated"  
                break               
            } 
            exit 
        }  
    }  
} 

function Get-PreReqs {
    <#
        .SYNOPSIS
        Check Installed software to verify the oscdimg command-line tool is installed

        .PARAMETER Software
        A pattern to match to Installed software.
    #>

    param (
        [string]$Software = 'oscdimg'
    )

    $64bitPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    $32bitPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

    $_software = Get-ChildItem -Path $32bitPath,$64bitPath | 
        Get-ItemProperty | Where-Object { $_.DisplayName -match $Software }

    if (!$_software) { Throw "oscdimg.exe was not found. Install the latest Windows ADK and try again." }

    return $true
}

# assign PSBoundParameters to local variable for use in functions
$_psBoundParameters = $PSBoundParameters

# define paths to use in script
$wimPath = "$Source\sources\install.wim"
$mountDirectory = "D:\Mount"
if (!(Test-Path $mountDirectory)) {
   $null = New-Item -Path $mountDirectory -ItemType Directory
}

[string]$message = ""

# verify script will run elevated
Use-RunAs 

# remove existing log files
Remove-Item $env:TEMP\WUSuccess.log, $env:TEMP\WUFail.log -Force -ErrorAction SilentlyContinue

#region choose updates to apply to image
    Add-Type -AssemblyName System.Windows.Forms

    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Title = "Select one or more Updates"
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Multiselect = $true
        Filter = "msu Files (*.msu)|*.msu|cab Files (*.cab)|*.cab"
    }

    $null = $FileBrowser.ShowDialog()

    # retrieve selected updates
    $updatesToApply = $FileBrowser.FileNames
    
    # garbage collection
    $FileBrowser.Dispose()

    # exit program if no updates returned
    if (!$updatesToApply) { Write-Host "No updates were selected. Exiting..."; Exit}
#endregion choose updates to apply to image

#region get image info (identify index)
Write-Host $message -ForegroundColor Cyan
Write-Host "Enumerating image..." -ForegroundColor Yellow    
$message += "Enumerating image..."
    if ($UsePowershell.IsPresent) { Get-WindowsImage -ImagePath $wimPath }
    else {
        # dism /get-imageinfo /imagefile:<Full path of the install.wim>
        dism /get-imageinfo /imagefile:$wimPath 
    }
    $message += "Done"

    $index = 6
    $ans = Read-Host -Prompt "Enter the Index of the image to update. Default is 6 (Windows Pro)"
    if ($ans) { $index = $ans }
    $message += "`nUser selected Image index $index"
#endregion get image info

#region Mount the Image
    Clear-Host
    Write-Host $message -ForegroundColor Cyan
    Write-Host "Mounting the Image..." -ForegroundColor Yellow
    $message += "`nMounting the Image..."

    # ensure the file is not Read-Only
    Set-ItemProperty -Path $wimPath -Name isReadOnly -Value $false

    if ($UsePowershell.IsPresent) { Mount-WindowsImage -ImagePath $wimPath -Path $mountDirectory -Index $index }
    else {
        # dism /mount-wim /wimfile:<Full path of the install.wim> /index:<Desired index number> /mountdir:<Full path of the mount folder location>
        dism /mount-wim /wimfile:$wimPath /index:$index /mountdir:$mountDirectory
    }
    $message += "Done"
#endregion mount the image

#region apply updates to the image
    Clear-Host
    Write-Host $message -ForegroundColor Cyan
    Write-Host "Applying the following updates`n$($updatesToApply | Out-String)" -ForegroundColor Yellow
    $message += "`nApplying updates..."
    foreach ($update in $updatesToApply) {
        if ($UsePowershell.IsPresent) { Add-WindowsPackage -Path $mountDirectory -PackagePath $update }
        else {
            #dism /add-package /image:<Full path of the mount folder location> /PackagePath:<Full path of the folder where you stored the update packages in step 5>
            dism /add-package /image:$mountDirectory /PackagePath:$update
        }

        if ($? -eq $true) { $update | Out-File -FilePath $env:TEMP\WUSuccess.log -Append }
        else { $update | Out-File -FilePath $env:TEMP\WUFail.log -Append }
    }

    if (Test-Path $env:TEMP\WUFail.log) {
        $failedUpdates = Get-Content $env:TEMP\WUFail.log
        Write-Host "Failed to apply the following updates`n$($failedUpdates)" -ForegroundColor Red 
    }
    else {
        Write-Host "All updates applied successfully." -ForegroundColor Green
    }
    $message += "Done"

    $ans = [System.Windows.Forms.MessageBox]::Show("Finished applying updates.`n`nClick 'Yes' to save changes and dismount the image.`nClick 'No' to Exit the script as is.`nClick 'Cancel' to dismount the image and discard changes.", "Image Updated",`
            [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, [System.Windows.Forms.MessageBoxIcon]::Question)
    
    switch ($ans) {
        'Yes' { $persist = @{ Save = $true }; $commit = "commit" }
        'No' { Exit }
        'Cancel' { $persist = @{ Discard = $true } ; $commit = "discard"; $cancel = $true}
    } 
#endregion apply updates to the image

#region dismount image, commit changes
    Clear-Host
    Write-Host $message -ForegroundColor Cyan
    Write-Host "Dismounting Image and Cleaning Up..." -ForegroundColor Yellow
    $message += "`nDismounting Image and Cleaning Up..."
    if ($UsePowershell.IsPresent) { Dismount-WindowsImage -Path $mountDirectory @persist }
    else {
        #dism /unmount-wim /mountdir:<Full path of the mount folder location> /commit
        dism /unmount-wim /mountdir:$mountDirectory /$commit
    }

    if ($?) { Remove-Item $mountDirectory -Force }
    else { Write-Host "Failed to dismount image" -ForegroundColor Red }

    if ($cancel) { Exit }
    
    $message += "Done"
    $ans = [System.Windows.Forms.MessageBox]::Show("Finished updating image.`n`nDo you want to create a new ISO?", "Image Updated",`
            [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    
    if ($ans -ne 'Yes') { Exit }
#endregion dismount image

#region create ISO
    try {
        Get-PreReqs
        Clear-Host
        Write-Host $message -ForegroundColor Cyan
        Write-Host "Creating the new ISO..." -ForegroundColor Yellow
        $message += "`nCreating the new ISO..."
        $oscdimg = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg\oscdimg.exe'
        
        <# OSCDIMG Syntax explaination:
        OSCDIMG.exe -l<disk_label> [options] -b<path_of_etfsboot.com_file> <path_of_installation_source> <path_of_ISO_to_be_created_with_filename>

        -l is used to set volume label of DVD
        -m is used to create bigger image file than 700MB
        -u2 is used to create UDF file system for DVD
        -b is used to locate boot image of DVD
        #>
        $cmd = "-l{0} -m -u2 -b`"{1}\boot\etfsboot.com`" `"{1}`" `"{2}`"" -f $DiskLabel,$Source,$Target

        $proc = Start-Process $oscdimg -ArgumentList $cmd -Wait -PassThru

        if ($proc.ExitCode -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Done creating new ISO.", "Success",`
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Failed to create new ISO", "Error",`
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
        $message += "Done"
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($error[0].Exception.Message, "Error",`
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
#endregion create ISO

Clear-Host
Write-Host $message -ForegroundColor Cyan
Pause