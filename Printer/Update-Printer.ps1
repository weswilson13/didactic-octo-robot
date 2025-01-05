<#
    .SYNOPSIS
    Manage one or more printers by updating the drivers and exporting/importing settings
    
    .PARAMETER PrinterName
    Specific printer(s) to target

    .PARAMETER PrintServer
    Name of the computer hosting the printing objects to target

    .PARAMETER ThrottleLimit
    Maxmimum number of parallel threads to run simultaneously (Powershell7 only)

    .PARAMETER BaseDriverName
    The driver family to target. Used to filter 

    .PARAMETER Driver
    Specific driver name to update printers with 

    .PARAMETER ExportProperties
    Export printer settings (properties and configurations) to an XML file

    .PARAMETER Properties
    Specific properties to export

    .PARAMETER PrinterPropertiesXML
    Filepath to the properties XML file

    .PARAMETER SetProperties
    Compares current printer settings to the stored settings, and updates the printer to mirror the previous configuration
    
    .PARAMETER WhatIf
    Will provide console indication without performing any action on printers

    .PARAMETER Force
    Force all aspects of the script to run:
        - Export all printer settings, for all printers on the print server
        - Update the print driver on all printers on the print server (unless specific printer(s) are supplied)
        - Set all printer settings to those found in $PrinterPropertiesXML

    .EXAMPLE
    Export all printer settings to default XML path in C:\Tools\PrinterConfiguration.xml

    Update-Printer.ps1 -ExportProperties

    .EXAMPLE 
    Update printer drivers with latest driver on print server

    Update-Printer.ps1 -UpdateDriver

    .EXAMPLE
    Update a single printer with a specified driver

    Update-Printer.ps1 -PrinterName 'printer1' -Driver 'HP Universal Printing PCL 6 (v7.3.0)'

    .EXAMPLE
    Compare/restore printer settings from a stored configuration

    Update-Printer.ps1 -SetProperties

#>
[cmdletbinding(DefaultParameterSetName='Update')]
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
    [Parameter(Mandatory=$false)]
    [string]$Driver,

    # Processor name of processor update
    [Parameter(Mandatory=$false)]
    [string]$Processor='hpcpp310',

    # Update print driver
    [Parameter(Mandatory=$false)]
    [switch]$UpdateDriver,

    # Update print processor
    [Parameter(Mandatory=$false)]
    [switch]$UpdateProcessor,

    # Exports printer properties to XML
    [Parameter(Mandatory=$false, ParameterSetName='Export')]
    [switch]$ExportProperties,

    # Specific properties to export
    [Parameter(Mandatory=$false, ParameterSetName='Export')]
    [string[]]$Properties,

    # XML file containing printer properties
    [Parameter(Mandatory=$false)]
    [string]$PrinterPropertiesXML,

    # Set printer properties from XML
    [Parameter(Mandatory=$false)]
    [switch]$SetProperties,

    # Take no action
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf,

    # Force settings update
    [Parameter(Mandatory=$false)]
    [switch]$Force
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

                $xmlWriter.WriteStartElement('Configuration')                              #     <Configuration>
                    $xmlWriter.WriteAttributeString('Collate', $printerConfig.Collate)
                    $xmlWriter.WriteAttributeString('Color', $printerConfig.Color)
                    $xmlWriter.WriteAttributeString('DuplexingMode', $printerConfig.DuplexingMode)
                $xmlWriter.WriteEndElement()
                    
                $xmlWriter.WriteStartElement('Properties')                              #     <Properties>
                    foreach ($property in $printerProperties) {
                        $xmlWriter.WriteStartElement('Property')                        #       <Property>
                        $xmlWriter.WriteAttributeString('Name', $property.PropertyName)   #         <Name>PropertyName</Name>
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

    if (!$Driver) { # get the latest driver from the print server that matches $BaseDriverName
        try { $Driver = (Get-PrinterDriver -Name "$BaseDriverName*" -ComputerName $PrintServer).Name | Sort-Object -Descending | Select-Object -First 1 }
        catch { throw "Failed to get latest driver from Print Server" }
    }
    else {
        
    }
    Write-Host "[INFO]: '$Driver' is the latest driver on the Print Server."

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

    $tools = switch ($env:COMPUTERNAME) {
        $PrintServer { 'C:\Tools' }
        default { "\\$PrintServer\C$\Tools" }
    }

    if (!$PrinterPropertiesXML) { # if a path isn't supplied, set a default path to XML file
        $PrinterPropertiesXML = "$tools\PrinterConfigurations.xml"
    }
    
    # create a new printer properties XML file
    if ($ExportProperties.IsPresent -or $Force.IsPresent) {
        New-PrinterConfig
        if (!$Force.IsPresent) { Exit }
    }

    # if ($SetProperties.IsPresent -or $Force.IsPresent) {
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

            $currentConfiguration = Get-PrintConfiguration -PrinterName $printer.Name -ComputerName $PrintServer
            $currentProperties = Get-PrinterProperty -PrinterName $printer.Name -ComputerName $PrintServer

            # Set configuration
            Write-Host "" -BackgroundColor White
            Write-Host "[INFO]: Evaluating Printer Configuration on $($printer.Name)" -ForegroundColor Blue -BackgroundColor White
            Write-Host "" -BackgroundColor White
            $configs = $_printerConfiguration | Get-Member -MemberType Property
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
                    Write-Host "[INFO]: $_configName is unchanged on $($printer.Name)" -ForegroundColor Gray
                }
            }

            # Set properties
            Write-Host "" -BackgroundColor White
            Write-Host "[INFO]: Evaluating Printer Properties on $($printer.Name)" -ForegroundColor Blue -BackgroundColor White
            Write-Host "" -BackgroundColor White
            foreach ($_property in $_printerProperties) {
                $_propertyName = $_property.Name
                $_propertyValue = $_printerProperties.Where( {$_.Name -eq $_propertyName} ).Value
                $currentPropertyValue = $currentProperties.Where({$_.PropertyName -eq $_propertyName}).Value

                if ($currentPropertyValue -ne $_propertyValue -or $Force.IsPresent) { # if the properties changed, reset them to the stored value
                    Write-Host "[ACTION]: Setting property '$_propertyName' from '$currentPropertyValue' to '$_propertyValue' on $($printer.Name)" -ForegroundColor Cyan
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
                    Write-Host "[INFO]: $_propertyName is unchanged on $($printer.Name)" -ForegroundColor Gray
                }
            }
        }
        
        $printer = $PSItem

        # check if printer is online
        if (!(Test-Connection $printer.Name -Count 2 -Quiet) -and $false <#remove this in production#>) { 
            Write-Host "$($printer.Name) is not pinging. Skipping this printer." -ForegroundColor Red
            Continue 
        }

       if ($PSEdition -eq 'Core') { # set variables for use in scriptblock based on powershell version
            $errorLog = $using:errorLog
            $PrintServer = $using:PrintServer
            $Driver = $using:Driver
            $Processor = $using:Processor
            $UpdateDriver = $using:UpdateDriver
            $UpdateProcessor = $using:UpdateProcessor
            $importedProperties = $using:importedProperties
            $SetProperties = $using:SetProperties
            $WhatIf = $using:WhatIf
            $Force = $using:Force
        }

        # update print driver
        if ($UpdateDriver.IsPresent -or $Force.IsPresent) {
            if ($printer.DriverName -ne $Driver) {
                Write-Host ""
                Write-Host "[ACTION]: Updating print driver on $($printer.Name) from '$($printer.DriverName)' to '$Driver'" -ForegroundColor Cyan
                if (!$WhatIf.IsPresent) {
                    try { Set-Printer -Name $printer.Name -DriverName $Driver -ComputerName $PrintServer }
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
        if (($UpdateProcessor.IsPresent -or $Force.IsPresent) -and $Processor) {
            if ($printer.PrintProcessor -ne $Processor) {
                Write-Host ""
                Write-Host "[ACTION]: Updating print processor on $($printer.Name) from '$($printer.PrintProcessor)' to '$Processor'" -ForegroundColor Cyan
                if (!$WhatIf.IsPresent) {
                    try { Set-Printer -Name $printer.Name -PrintProcessor $Processor -ComputerName $PrintServer }
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
        if (($SetProperties.IsPresent -or $Force.IsPresent) -and $importedProperties) { Set-PrinterProperties }
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