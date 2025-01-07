<#
    .SYNOPSIS
    Manage one or more printers by updating the driver, processor, and exporting/importing settings

    .DESCRIPTION
    Can 
    
    .PARAMETER PrinterName
    Specific printer(s) to target

    .PARAMETER PrintServer
    Name of the computer hosting the printing objects to target

    .PARAMETER ThrottleLimit
    Maxmimum number of parallel threads to run simultaneously (Powershell7 only)

    .PARAMETER BaseDriverName
    The driver family to target. Used to filter 

    .PARAMETER DriverName
    Specific driver name to update printers with 

    .PARAMETER UpdateDriver
    Executes driver update code

    .PARAMETER ProcessorName
    Processor name to update printers with

    .PARAMETER UpdateProcessor
    Executes processor update code

    .PARAMETER ExportSettings
    Export printer settings (properties and configurations) to an XML file

    .PARAMETER Properties
    Specific properties to export

    .PARAMETER Configurations
    Specific configurations to export

    .PARAMETER PrinterPropertiesXML
    Filepath to the properties XML file

    .PARAMETER ImportSettings
    Compares current printer settings to the stored settings, and updates the printer to mirror the previous configuration
    
    .PARAMETER WhatIf
    Will provide console indication without performing any action on printers

    .PARAMETER Force
    Force all aspects of the script to run:
        - Export all printer settings, for all printers on the print server
        - Update the print driver on all printers on the print server (unless specific printer(s) are supplied)
        - Set all printer settings to those found in $PrinterPropertiesXML

    .PARAMETER Test
    Wait for user acknowledgement before applying each action

    .EXAMPLE
    Export all printer settings to default XML path in C:\Tools\PrinterConfiguration.xml

    Update-Printer.ps1 -ExportSettings

    .EXAMPLE 
    Update printer drivers with latest driver on print server

    Update-Printer.ps1 -UpdateDriver

    .EXAMPLE
    Update a single printer with a specified driver

    Update-Printer.ps1 -PrinterName 'printer1' -Driver 'HP Universal Printing PCL 6 (v7.3.0)'

    .EXAMPLE
    Update print driver with the latest on the server and update the print processor

    Update-Printer.ps1 -UpdateDriver -UpdateProcessor -ProcessorName hpcpp310

    .EXAMPLE
    Compare/restore printer settings from a stored configuration

    Update-Printer.ps1 -ImportSettings

#>
[cmdletbinding(DefaultParameterSetName='ExportSettings')]
param(
    # Printer Name(s)
    [Parameter(Mandatory=$false)]
    [string[]]$PrinterName,

    # Print Server
    [Parameter(Mandatory=$false)]
    [string]$PrintServer = 'PS01',

    # Max number of parallel threads (PS7 only)
    [Parameter(Mandatory=$false)]
    [byte]$ThrottleLimit=10,

    # Base driver name of the printer family (i.e - version agnostic)
    [Parameter(Mandatory=$false)]
    [string]$BaseDriverName = 'HP Universal Printing PCL',

    # Driver name of driver update
    [Parameter(Mandatory=$false, ParameterSetName='ImportSettings')]
    [string]$DriverName,

    # Processor name of processor update
    [Parameter(Mandatory=$false, ParameterSetName='ImportSettings')]
    [string]$ProcessorName='hpcpp310',

    # Update print driver
    [Parameter(Mandatory=$false, ParameterSetName='ImportSettings')]
    [switch]$UpdateDriver,

    # Update print processor
    [Parameter(Mandatory=$false, ParameterSetName='ImportSettings')]
    [switch]$UpdateProcessor,

    # Exports printer properties to XML
    [Parameter(Mandatory=$true, ParameterSetName='ExportSettings')]
    [switch]$ExportSettings,

    # Specific properties to export
    [Parameter(Mandatory=$false, ParameterSetName='ImportSettings')]
    [Parameter(Mandatory=$false, ParameterSetName='ExportSettings')]
    [ValidateScript({ 
        if ($_.StartsWith("Config")) { 
            return $true 
        }
        else {
            throw "The supplied value '$_' does not match the format 'Config:<property>'" 
        } 
    })]
    [string[]]$Properties,

    # Specific configurations to export
    [Parameter(Mandatory=$false, ParameterSetName='ImportSettings')]
    [ValidateSet('Collate','Color','DuplexingMode')]
    [string[]]$Configurations,

    # XML file containing printer properties
    [Parameter(Mandatory=$false)]
    [string]$PrinterPropertiesXML,

    # Set printer properties from XML
    [Parameter(Mandatory=$false, ParameterSetName='ImportSettings')]
    [switch]$ImportSettings,

    # Take no action
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf,

    # Force all actions
    [Parameter(Mandatory=$false)]
    [switch]$Force,

    # Step through actions
    [Parameter(Mandatory=$false)]
    [switch]$Test
)
begin {
    function Use-RunAs {
        # TO DO
    }
    function New-PrinterConfig {
        <#
            .SYNOPSIS 
            Create an XML file containing the properties for the specified printers.
        #>
        if (Test-Path $PrinterPropertiesXML) { # a config file already exists
            $message = "A printer properties file already exists at $PrinterPropertiesXML. Do you want to overwrite it?"
            $ans = [System.Windows.Forms.MessageBox]::Show($message, "Export Printer Properties", `
                [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Exclamation, `
                [System.Windows.Forms.MessageBoxDefaultButton]::Button1,[System.Windows.Forms.MessageBoxOptions]::ServiceNotification)
            
            if ($ans -eq 'No') { Exit }
        }
        Write-Host "[INFO]: Exporting printer properties to $PrinterPropertiesXML" -ForegroundColor Gray

        # Remove-Item $PrinterPropertiesXml -Force -ErrorAction SilentlyContinue

        $xmlWriter = New-Object System.Xml.XmlTextWriter($PrinterPropertiesXml,$null)
        $xmlWriter.Formatting = 'Indented'
        $xmlWriter.Indentation = 1
        $XmlWriter.IndentChar = "`t"
        $xmlWriter.WriteStartDocument()
        $xmlWriter.WriteComment("Printer Settings [$(Get-Date -Format 'MM\\dd\\yyyy')]") # <!-- Printer Properties -->
        $xmlWriter.WriteStartElement('Printers')                                         # <Printers>
        foreach ($printer in $printers) {
            $printParams = @{
                PrinterName = $printer.Name
                ComputerName = $PrintServer
            }
            
            $printerConfig = Get-PrintConfiguration @printParams
            
            if ($Properties) {
                $printParams.Add("PropertyName", $Properties)
            }
            $printerProperties = Get-PrinterProperty @printParams

            $xmlWriter.WriteStartElement('Printer')                                     #   <Printer>
                $xmlWriter.WriteAttributeString('Name', $printer.Name)
                $xmlWriter.WriteAttributeString('DriverName', $printer.DriverName)
                $xmlWriter.WriteAttributeString('PrintProcessor', $printer.PrintProcessor)
                $xmlWriter.WriteAttributeString('Published', $printer.Published)

                $xmlWriter.WriteStartElement('Configuration')                              #     <Configuration>
                    $xmlWriter.WriteAttributeString('Collate', $printerConfig.Collate)
                    $xmlWriter.WriteAttributeString('Color', $printerConfig.Color)
                    $xmlWriter.WriteAttributeString('DuplexingMode', $printerConfig.DuplexingMode)
                $xmlWriter.WriteEndElement()
                    
                $xmlWriter.WriteStartElement('Properties')                              #     <Properties>
                    foreach ($property in $printerProperties) {
                        $xmlWriter.WriteStartElement('Property')                        #       <Property>
                        $xmlWriter.WriteAttributeString('PropertyName', $property.PropertyName)   #         <Name>PropertyName</Name>
                        $xmlWriter.WriteAttributeString('Type', $property.Type)           #         <Type>Type</Type>
                        $xmlWriter.WriteAttributeString('Value', $property.Value)         #         <Value>Value</Value>
                        $xmlWriter.WriteEndElement()                                    #       </Property>
                    }
                $xmlWriter.WriteEndElement()                                            #     </Properties>
            
            $xmlWriter.WriteEndElement()                                                #   </Printer>
        }
        $xmlWriter.WriteEndElement()                                                    # </Printers>
        $xmlWriter.WriteEndDocument()
        $xmlWriter.Flush()
        $xmlWriter.Close()
    }
    
    Add-Type -AssemblyName System.Windows.Forms

    $errorLog = "C:\tools\PrinterUpdateErrors.log"

    $tools = switch ($env:COMPUTERNAME) {
        $PrintServer { 'C:\Tools' }
        default { "\\$PrintServer\C$\Tools" }
    }

    if (!$PrinterPropertiesXML) { # if a path isn't supplied, set a default path to XML file
        $PrinterPropertiesXML = "$tools\PrinterConfigurations.xml"
    }

    switch ($PSBoundParameters.Keys) {
        'PrinterName' { Write-Host "[INIT]: Targeting $($PrinterName -join ', ')" -ForegroundColor Yellow }
        'PrintServer' { Write-Host "[INIT]: Running against $PrintServer" -ForegroundColor Yellow }
        'BaseDriverName' { Write-Host "[INIT]: Filtering by $BaseDriverName" -ForegroundColor Yellow }
        'ImportSettings' { Write-Host "[INIT]: Importing settings from $PrinterPropertiesXML" -ForegroundColor Yellow }
        'ExportSettings' { Write-Host "[INIT]: Exporting current printer settings to $PrinterPropertiesXML" -ForegroundColor Yellow }
        'UpdateDriver' { switch ($DriverName) {
            {[string]::IsNullOrWhiteSpace($PSItem)} { Write-Host "[INIT]: Updating print driver to latest on $PrintServer" -ForegroundColor Yellow; break }
            default { Write-Host "[INIT]: Updating print driver to $DriverName" -ForegroundColor Yellow }
        } }
        'UpdateProcessor' { Write-Host "[INIT]: Updating print processor to $ProcessorName" -ForegroundColor Yellow }
        'Force' { Write-Host "[INIT]: Forcing execution of all actions" -ForegroundColor Yellow }
        'Test' { Write-Host "[INIT]: User acknowledgement will be needed before performing actions" -ForegroundColor Yellow }
    }
    Write-Host ""
    Pause

    if ($UpdateDriver.IsPresent -or $Force.IsPresent) {
        if (!$DriverName) { # get the latest driver from the print server that matches $BaseDriverName
            try { $DriverName = (Get-PrinterDriver -Name "$BaseDriverName*" -ComputerName $PrintServer).Name | Sort-Object -Descending | Select-Object -First 1 }
            catch { throw "Failed to get latest driver from Print Server" }
        }
        
        Write-Host "[INFO]: '$DriverName' is the latest driver on the Print Server."
    }

    try { # get printers to evaluate
        if (!$PrinterName) {
            $printers = Get-Printer -ComputerName $PrintServer | Where-Object { $_.DriverName -match $BaseDriverName }
        }
        else {
            $printers = Get-Printer -Name $PrinterName -ComputerName $PrintServer
        }
    }
    catch {
        throw "Failed to get printer(s) from Print Server"
    }
    
    # create a new printer properties XML file
    if ($ExportSettings.IsPresent -or $Force.IsPresent) {
        New-PrinterConfig
        if (!$Force.IsPresent) { Exit }
    }

    # if ($ImportSettings.IsPresent -or $Force.IsPresent) {
        # import stored printer properties
        if (!(Test-Path $PrinterPropertiesXML)) {
            Write-Warning "$PrinterPropertiesXML does not exist!"
        }
        else {
            $importedProperties = [xml](Get-Content $PrinterPropertiesXML)
        }
    # }

    $scriptblock = {
        function Set-PrinterProperties {
            $_printerData = $importedProperties.Printers.Printer.Where({$_.Name -eq $printer.Name})
            $_printerConfiguration = $_printerData.Configuration
            $_printerProperties = $_printerData.Properties.Property
            if ($Properties) { # filter out only the properties supplied
                $_printerProperties = $_printerProperties.Where({ $_.Name -in $Properties })
            }

            $currentConfiguration = Get-PrintConfiguration -PrinterName $printer.Name -ComputerName $PrintServer
            $currentProperties = Get-PrinterProperty -PrinterName $printer.Name -ComputerName $PrintServer

            # Set configuration
            Write-Host "" -BackgroundColor White
            Write-Host "[INFO]: Evaluating Printer Configuration on $($printer.Name)" -ForegroundColor DarkBlue -BackgroundColor White
            Write-Host "" -BackgroundColor White
            $configs = $_printerConfiguration | Get-Member -MemberType Property
            if ($Configurations) { # filter out only the configurations supplied
                $configs = $configs.Where({ $_.Name -in $Configurations })
            }
            foreach ($config in $configs) {
                $_configName = $config.Name
                $_configValue = switch ($_printerConfiguration.$_configName) { # Collate and Color configs are bool types
                    'True' { 1 }
                    'False' { 0 }
                    default { $PSItem }
                }
                $currentConfigValue = $currentConfiguration.$_configName
                if ($currentConfigValue -ne $_configValue -or $Force.IsPresent) {
                    Write-Host "[ACTION]: Setting property '$_configName' from '$currentConfigValue' to '$_configValue' on $($printer.Name)" -ForegroundColor Cyan
                    if ($Test.IsPresent) { Pause }
                    if (!$WhatIf.IsPresent) {
                        $setConfigurationParams = @{
                            PrinterName = $printer.Name
                            $($_configName) = $_configValue
                            ComputerName = $PrintServer
                        }
                        try { Set-PrintConfiguration @setConfigurationParams }
                        catch { 
                            Write-Host "[ERROR]: Failed to set config '$_configName'" -ForegroundColor Red
                            Out-File -InputObject $error[0].Exception.Message -FilePath $errorLog -Encoding ascii -Append
                        }
                    }
                }
                else {
                    Write-Host "[INFO]: '$_configName' is unchanged on $($printer.Name)" -ForegroundColor Gray
                }
            }

            # Set properties
            Write-Host "" -BackgroundColor White
            Write-Host "[INFO]: Evaluating Printer Properties on $($printer.Name)" -ForegroundColor DarkBlue -BackgroundColor White
            Write-Host "" -BackgroundColor White
            foreach ($_property in $_printerProperties) {
                $_propertyName = $_property.Name
                $_propertyValue = $_printerProperties.Where( {$_.Name -eq $_propertyName} ).Value
                $currentPropertyValue = $currentProperties.Where({$_.PropertyName -eq $_propertyName}).Value

                if ($currentPropertyValue -ne $_propertyValue -or $Force.IsPresent) { # if the properties changed, reset them to the stored value
                    Write-Host "[ACTION]: Setting property '$_propertyName' from '$currentPropertyValue' to '$_propertyValue' on $($printer.Name)" -ForegroundColor Cyan
                    if ($Test.IsPresent) { Pause }
                    if (!$WhatIf.IsPresent) {
                        $setPropertyParams = @{
                            PrinterName = $printer.Name
                            PropertyName = $_propertyName
                            Value = $_propertyValue
                            ComputerName = $PrintServer
                        }
                        try { Set-PrinterProperty @setPropertyParams }
                        catch { 
                            Write-Host "[ERROR]: Failed to set property '$_propertyName'" -ForegroundColor Red
                            Out-File -InputObject $error[0].Exception.Message -FilePath $errorLog -Encoding ascii -Append
                        }
                    }
                }
                else {
                    Write-Host "[INFO]: '$_propertyName' is unchanged on $($printer.Name)" -ForegroundColor Gray
                }
            }
        }
        
        $printer = $PSItem

        # check if printer is online
        if (!(Test-Connection $printer.Name -Count 2 -Quiet) -and $false <#remove this in production#>) { 
            Write-Host "$($printer.Name) is not pinging. Skipping this printer." -ForegroundColor Red
            Continue 
        }

       if ($PSEdition -eq 'Core') { # parallel process block requires 'using' predecessor to access variables outside of scriptblock
            $errorLog = $using:errorLog
            $PrintServer = $using:PrintServer
            $DriverName = $using:DriverName
            $ProcessorName = $using:ProcessorName
            $UpdateDriver = $using:UpdateDriver
            $UpdateProcessor = $using:UpdateProcessor
            $importedProperties = $using:importedProperties
            $ImportSettings = $using:ImportSettings
            $WhatIf = $using:WhatIf
            $Force = $using:Force
            $Test = $using:Test
        }

        # update print driver
        if ($UpdateDriver.IsPresent -or $Force.IsPresent) {
            if ($printer.DriverName -ne $DriverName) {
                Write-Host ""
                Write-Host "[ACTION]: Updating print driver on $($printer.Name) from '$($printer.DriverName)' to '$DriverName'" -ForegroundColor Cyan
                if (!$WhatIf.IsPresent) { # If -WhatIf is not used, perform the driver update
                    if ($Test.IsPresent) { Pause }
                    try { Set-Printer -Name $printer.Name -DriverName $DriverName -ComputerName $PrintServer }
                    catch { 
                        Write-Host "[ERROR]: Failed to update print driver" -ForegroundColor Red
                        Out-File -InputObject $error[0].Exception.Message -FilePath $errorLog -Encoding ascii -Append
                    }
                }
            }
            else {
                Write-Host "[INFO]: Print driver on $($printer.Name) is already up to date" -ForegroundColor Gray 
            }
        }

        # update print processor
        if (($UpdateProcessor.IsPresent -or $Force.IsPresent) -and $ProcessorName) {
            if ($printer.PrintProcessor -ne $ProcessorName) {
                Write-Host ""
                Write-Host "[ACTION]: Updating print processor on $($printer.Name) from '$($printer.PrintProcessor)' to '$ProcessorName'" -ForegroundColor Cyan
                if ($Test.IsPresent) { Pause }
                if (!$WhatIf.IsPresent) { # If -WhatIf is not used, perform the processor update
                    try { Set-Printer -Name $printer.Name -PrintProcessor $ProcessorName -ComputerName $PrintServer }
                    catch { 
                        Write-Host "[ERROR]: Failed to update print processor" -ForegroundColor Red
                        Out-File -InputObject $error[0].Exception.Message -FilePath $errorLog -Encoding ascii -Append
                    }
                }
            }
            else {
                Write-Host "[INFO]: Print processor on $($printer.Name) is already up to date" -ForegroundColor Gray 
            }
        }

        # set printer properties from XML file
        if (($ImportSettings.IsPresent -or $Force.IsPresent) -and $importedProperties) { Set-PrinterProperties }
    }

    $params = switch ($PSEdition) {
        'Desktop' { @{ Process = $scriptblock }}
        'Core' { @{ ThrottleLimit = $ThrottleLimit; Parallel = $scriptblock }}
    }
}

process {
    $printers | ForEach-Object @params
}

end {
    Write-Host "Finished" -ForegroundColor Blue
}