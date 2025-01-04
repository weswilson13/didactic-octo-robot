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

    # XML file containing printer properties
    [Parameter(Mandatory=$false)]
    [string]$PrinterPropertiesXML
)

begin {
    function New-PrinterConfig {
        Remove-Item $PrinterPropertiesXml -Force

        $xmlWriter = New-Object System.Xml.XmlTextWriter($PrinterPropertiesXml,$null)
        $xmlWriter.Formatting = 'Indented'
        $xmlWriter.Indentation = 1
        $XmlWriter.IndentChar = "`t"
        $xmlWriter.WriteStartDocument()
        $xmlWriter.WriteComment('Printer Properties')                                   # <!-- Printer Properties -->
        $xmlWriter.WriteStartElement('Printers')                                        # <Printers>
        foreach ($printer in $printers) {
            $printParams = @{
                PrinterName = $printer.Name
                ComputerName = $PrintServer
            }
            $printerProperties = Get-PrinterProperty @printParams

            $xmlWriter.WriteStartElement('Printer')                                     #   <Printer>
                $xmlWriter.WriteAttributeString('Name', $printer.Name)
                $xmlWriter.WriteAttributeString('DriverName', $printer.DriverName)
            
                $xmlWriter.WriteStartElement('Properties')                              #     <Properties>
                    foreach ($property in $printerProperties) {
                        $xmlWriter.WriteStartElement('Property')                        #       <Property>
                        $xmlWriter.WriteElementString('Name', $property.PropertyName)   #         <Name>PropertyName</Name>
                        $xmlWriter.WriteElementString('Type', $property.Type)           #         <Type>Type</Type>
                        $xmlWriter.WriteElementString('Value', $property.Value)         #         <Value>Value</Value>
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
        try { (Get-PrinterDriver -Name $BaseDriverName*).Name | Sort-Object -Descending | Select-Object -First 1 }
        catch { throw "Failed to get latest driver from Print Server" }
    }
    else {
        
    }

    $tools = switch ($env:COMPUTERNAME) {
        $PrintServer { 'C:\Tools' }
        default { "\\$PrintServer\C$\Tools" }
    }


    # export printer properties
    if (!$PrinterPropertiesXML) {
        $PrinterPropertiesXML = "$tools\PrinterConfigurations.xml"
    }
    
    New-PrinterConfig

    $scriptblock = {
        
        $printer = $PSItem
        if (!(Test-Connection $printer.Name -Count 2 -Quiet) -and $false) { 
            Write-Host "$($printer.Name) is not pinging. Skipping this printer." -ForegroundColor Red; Continue 
        }
        Write-Host $printer

        switch ($PSEdition) {
            'Desktop' {
                $_printServer = $PrintServer
                $_driver = $Driver
            }
            'Core' {
                $_printServer = $using:PrintServer
                $_driver = $using:Driver
            }
        }

        # enable Mopier Mode
        # Set-PrinterProperty -PrinterName $printer.Name -PropertyName Config:DeviceIsMopier -Value Installed -Verbose -ComputerName $_printServer
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