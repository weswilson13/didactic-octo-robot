param (
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [String[]] $ComputerName
)

try {
    #Add-Type -Path 'C:\Program Files (x86)\Microsoft.NET\Primary Interop Assemblies\Microsoft.mshtml.dll'
    #Add-Type -AssemblyName "Microsoft.mshtml"

    #$webpage = New-Object mshtml.HTMLDocumentClass
    #$html = New-Object -ComObject "HTMLFile"

    $logPath = "$PSScriptRoot\ScriptLogs\DefinitionUpdate.log"
    
    # Get latest security intelligence executable
    $definitionFilePath = "\\192.168.1.4\NAS05\Updates\Defender\WindowsDefenderDefinitions.exe"
    #$webpage = Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/wdsi/defenderupdates"
    #$latestDefinitions = $webpage.ParsedHtml.GetElementById("dateofrelease").innerHTML
    #Out-File -InputObject "new definitions released: $latestDefinitions" -FilePath $logPath -Encoding utf8 -Append
    
    #if ($(Get-ItemProperty $definitionFilePath).LastWriteTime -lt (Get-Date -Format 'MM-dd-yyyy')) {
        Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?LinkID=121721&arch=x64" -OutFile $definitionFilePath
    #}

    if (!$ComputerName) {
        $ComputerName = Get-ADComputer -Filter 'OperatingSystem -like "*Server*"' -Properties * | Select-Object -ExpandProperty DNSHostName
    }

    foreach ($server in $ComputerName) {
        $server
        if (Test-Connection $server -Count 2 -Quiet) { 
            #Start-Job -ScriptBlock { 
                $logAttributes = @{
                        FilePath = $logPath 
                        Encoding = 'ascii'
                        Append = $true
                }
                $currentDefinition = Get-MpComputerStatus -CimSession $server | Select-Object -ExpandProperty AntispywareSignatureVersion
                Out-File @logAttributes -InputObject "[$(Get-Date)]: Current version on $($server): $currentDefinition`r`n"

                & "$($PSScriptRoot)\Install-MsiExeUpdate.ps1" -ComputerName $server -Type Defender -DefenderVersion $currentDefinition 

                $updatedDefinitions = Get-MpComputerStatus -CimSession $server | Select-Object -Property AntispywareSignatureVersion, *LastUpdated
                Out-File @logAttributes -InputObject ("Updated signature versions on $($server):`r`t" +
                    "AntispywareSignatureVersion: $($updatedDefinitions.AntispywareSignatureVersion)`r`t" +
                    "AntispywareSignatureLastUpdated: $($updatedDefinitions.AntispywareSignatureLastUpdated)`r`t" +
                    "AntivirusSignatureLastUpdated: $($updatedDefinitions.AntivirusSignatureLastUpdated)`r`t" +
                    "NISSignatureLastUpdated: $($updatedDefinitions.NISSignatureLastUpdated)`r")
            #} -ArgumentList $server, $logPath, $PSScriptRoot
        }    
    }
} Catch {
    $Error[0]
}

