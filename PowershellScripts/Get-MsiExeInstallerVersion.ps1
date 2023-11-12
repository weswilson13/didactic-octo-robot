#requires -Modules MSI
param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)] 
    [ValidateNotNullOrEmpty()] 
    [System.IO.FileInfo] $Path
) 
if (!(Test-Path $Path.FullName)) { 
    throw "File '{0}' does not exist" -f $Path.FullName 
} 
try {
    $matchAttr = @{
        InputObject = 
            $(switch ($Path.Extension) {  
                '.msi' { (Get-MSIProperty -Property ProductVersion -Path $Path.FullName).Value }
                '.exe' { (Get-ItemProperty -Path $Path.FullName).VersionInfo.FileVersion }
            })
        Pattern = '\d+\.\d+\.\d+(_\d+)?'
    }
    $Version = (Select-String @matchAttr).Matches.Value 
    return $Version
} catch { 
    throw "Failed to get file version: {0}." -f ($_ | Select-Object *)
}      