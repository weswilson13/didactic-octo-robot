[cmdletbinding()]
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
    [string]
    $BaseDriverName = 'HP Universal Printing PCL',

    # Driver name of driver update
    [Parameter(Mandatory=$false)]
    [string]$Driver,

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
    [switch]$WhatIf
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
                [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
            
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

    try {
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

    if (!$Driver) {
        try { $Driver = (Get-PrinterDriver -Name "$BaseDriverName*" -ComputerName $PrintServer).Name | Sort-Object -Descending | Select-Object -First 1 }
        catch { throw "Failed to get latest driver from Print Server" }
    }
    else {
        
    }
    Write-Host "[INFO]: '$Driver' is the latest driver on the Print Server."

    $tools = switch ($env:COMPUTERNAME) {
        $PrintServer { 'C:\Tools' }
        default { "\\$PrintServer\C$\Tools" }
    }

    if (!$PrinterPropertiesXML) { # if a path in't supplied, set a default path to XML file
        $PrinterPropertiesXML = "$tools\PrinterConfigurations.xml"
    }
    
    # create a new printer properties XML file
    if ($ExportProperties.IsPresent) {
        New-PrinterConfig
        Exit
    }

    if ($SetProperties.IsPresent) {
        # import stored printer properties
        if (!(Test-Path $PrinterPropertiesXML)) {
            Write-Warning "$PrinterPropertiesXML does not exist!"
        }
        else {
            $importedProperties = [xml](Get-Content $PrinterPropertiesXML)
        }
    }

    $scriptblock = {
        function Set-PrinterProperties {
            $_printerData = $_importedProperties.Printers.Printer.Where({$_.Name -eq $printer.Name})
            $_printerConfiguration = $_printerData.Configuration
            $_printerProperties = $_printerData.Properties.Property

            $currentConfiguration = Get-PrintConfiguration -PrinterName $printer.Name -ComputerName $_printServer
            $currentProperties = Get-PrinterProperty -PrinterName $printer.Name -ComputerName $_printServer

            # Set configuration
            $configs = $_printerConfiguration | Get-Member -MemberType Property
            $configs | out-string | Write-Host
            foreach ($config in $configs) {
                $_configName = $config.Name
                $_configValue = $_printerConfiguration.$_configName
                $_configValue = switch ($_configValue) {
                    'True' { 1 }
                    'False' { 0 }
                    default { $PSItem }
                }
                $currentConfigValue = $currentConfiguration.$_configName
                if ($currentConfigValue -ne $_configValue -or $true) {
                    Write-Host "[INFO]: Setting property '$_configName' from '$currentConfigValue' to '$_configValue' on $($printer.Name)" -ForegroundColor Gray
                    if (!$_whatIf.IsPresent) {
                        $setConfigurationParams = @{
                            PrinterName = $printer.Name
                            $($_configName) = $_configValue
                            ComputerName = $_printServer
                        }
                        $setConfigurationParams | Out-String | Write-Host
                        try { Set-PrintConfiguration @setConfigurationParams }
                        catch { 
                            Write-Host "[ERROR]: Failed to set config '$_configName'" -ForegroundColor Red
                            Out-File -InputObject $error[0].Exception.Message -FilePath $_errorLog -Encoding ascii -Append
                        }
                    }
                }
            }

            # Set properties
            foreach ($_property in $_printerProperties) {
                $_propertyName = $_property.Name
                $_propertyValue = $_printerProperties.Where( {$_.Name -eq $_propertyName} ).Value
                $currentPropertyValue = $currentProperties.Where({$_.PropertyName -eq $_propertyName}).Value
                if ($currentPropertyValue -ne $_propertyValue) {
                    Write-Host "[INFO]: Setting property '$_propertyName' from '$currentPropertyValue' to '$_propertyValue' on $($printer.Name)" -ForegroundColor Gray
                    if (!$_whatIf.IsPresent) {
                        $setPropertyParams = @{
                            PrinterName = $printer.Name
                            PropertyName = $_propertyName
                            Value = $_propertyValue
                            ComputerName = $_printServer
                        }
                        try { Set-PrinterProperty @setPropertyParams }
                        catch { 
                            Write-Host "[ERROR]: Failed to set property '$_propertyName'" -ForegroundColor Red
                            Out-File -InputObject $error[0].Exception.Message -FilePath $_errorLog -Encoding ascii -Append
                        }
                    }
                }
            }
        }
        $printer = $PSItem

        # check if printer is online
        if (!(Test-Connection $printer.Name -Count 2 -Quiet) -and $false <#remove this in production#>) { 
            Write-Host "$($printer.Name) is not pinging. Skipping this printer." -ForegroundColor Red
            Continue 
        }

        switch ($PSEdition) {
            'Desktop' {
                $_errorLog = $errorLog
                $_printServer = $PrintServer
                $_driver = $Driver
                $_importedProperties = $importedProperties
                $_setProperties = $SetProperties
                $_whatIf = $WhatIf
            }
            'Core' {
                $_errorLog = $using:errorLog
                $_printServer = $using:PrintServer
                $_driver = $using:Driver
                $_importedProperties = $using:importedProperties
                $_setProperties = $using:SetProperties
                $_whatIf = $using:WhatIf
            }
        }

        # set printer properties from XML file
        if ($_setProperties.IsPresent -and $_importedProperties) { Set-PrinterProperties }
        
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
    
}