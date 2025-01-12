# ![NNPTC](NNPTC_Logo.JPG) NNPTC Printer Management Script - *Update-Printer.ps1*

*Author: Wes Wilson*  
*Last Updated: 1/6/2025*

This script can complete most aspects of printer management, with the exception of firmware updates. Making use of the PrintManagement Powershell module, an administrator can do any combination of the following:
* Query printer properties and configrations 
* Export printer properties and configurations to an XML file
* Import printer properties and settings from an XML file
* Update the printer driver
* Update the printer processor
* Publish the printer to the printer directory

**Required to be executed locally on the print server**
## Script Parameters

### PrinterName
(Optional)  
[string[]]  
Accepts a string array of printer names to target the desired actions.
### PrintServer
(Optional) 
[byte]
The computer or server hosting the target printers.
### ThrottleLimit
Optional. When running in Powershell7, controls the maximum number of parallel threads. This can speed up operation significantly.
### BaseDriverName
Optional. The base name of the driver version installed on the printers. Used to filter the printers on the print server. Default value is 'HP Universal Printing PCL'
### UpdateDriver
Optional. 
### DriverName
### UpdateProcessor
### PrinterPropertiesXML
### ProcessorName
### QuerySettings
### ExportSettings
### ImportSettings
### Configurations
### Properties
### ListInDirectory
### WhatIf
### Test
### Force

## Query Printer Settings
Current printer settings can be queried and returned to the console. Variations of the command can be executed to modify the printers and properties queried.

```powershell
# Query configuration and all properties for all printers on the print server

Update-Printer -QuerySettings

# Query configuration and specific properties for an array of printers

Update-Printer -QuerySettings -PrinterName 'NNPTC1-2400-P209-MFP578-012314', 'NNPTC-2400-D216-XXX-01318' -Properties 'Config:DeviceIsMopier', 'Config:DuplexUnit'
```

## Export Printer Settings
Printer configuration and properties can be exported to an XML file. This export includes the following attributes for each printer:
* Printer name
* Driver name
* Processor name
* Published state
* Configuration settings
  * Collate, Color, and Duplexing Mode
* Properties
  * Property Name
  * data type
  * value

The intent is that this would be done with the printers at their final configuration. This export can be used to verify settings following driver and firmware updates, or read into powershell and manipulated as desired.

When exporting, the default method is to export individual XML files for each printer. 

When running on the **local machine**, the user will be presented with a message box acknowledging the export method. The file(s) will be saved corresponding to the value of `$PrinterPropertiesXML`. If individual files are to be exported, a folder called *PrinterSettings* will be created in the parent directory of the file specified by `$PrinterPropertiesXML` with each XML filename set to the printer name. If the file to be exported already exists, the user will be prompted before overwriting. 

When the script is executed **remotely** (e.g. - PSRemoting), user prompts are bypassed and the default action is taken. The default action is to export indiviual XML files and to *overwrite* any existing files.  

```powershell
# Export all configurations and all properties for all printers on the print server

Update-Printer -ExportSettings

# Export all configurations and specific properties for a single printer. Specify the output filepath.

Update-Printer -ExportSettings -Properties Config:DeviceIsMopier -PrinterName 'NNPTC1-2400-P209-MFP578-012314' -PrinterPropertiesXML C:\Tools\PrinterSettings.xml
```
![alt text](PrinterPropertiesXML.PNG)

## Import Printer Settings
Printer settings can be compared against and updated from the XML files created above. This feature can check against all settings, or just specific properties supplied to the -Properties parameter. 

Preferentially, the script looks for the corresponding printer XML file for the printer in focus. If an individual XML file does not exist, the "bulk" XML file is parsed for the missing configurations. 

Unless a custom path is supplied via -PrinterPropertiesXML, the script looks for the bulk XML file at C:\Tools\PrinterSettings.xml. Individual files are located in the parent directory of the -PrinterPropertiesXML value in a folder called *PrinterSettings*.

The -WhatIf switch can be used to see wha t actions will be performed, without actually manipulating any printer settings.

```powershell
# compare a specific printer against stored settings

Update-Printer -ImportSettings -PrinterName 'NNPTC1-2400-P209-MFP578-012314'
```

## Set Print Driver
Set the printer driver for one or more printers. The -DriverName parameter can be used to target a specific driver. If this switch is not used, all drivers matching the -BaseDriverName value will be evaluated and the latest driver will be used. 

```powershell
# Set the driver on all printers to the latest on the print server

Update-Printer -UpdateDriver 

# Set the print driver on a specific printer to a specific driver version

Update-Printer -PrinterName 'NNPTC1-2400-P209-MFP578-012314' -UpdateDriver -DriverName 'HP Universal Printing (v7.1.0)'
```

## Set Print Processor
Set the printer processor for one or more printers. The -ProcessorName parameter can be used to target a specific processor. If this switch is not used, the default value will be used. Currently, this default value is set to **hpcpp310**.

```powershell
# Set the print processor on all printers to the default processor

Update-Printer -UpdateProcessor

# Set the print processor on a specific printer to a specific processor

Update-Printer -PrinterName 'NNPTC1-2400-P209-MFP578-012314' -UpdateProcessor -ProcessorName ''
```

## Publish Printer to Printer Directory

If a printer is unable to be found in the printer directory, chances are that it is not published. That can be done using the -ListInDirectory switch.

```powershell
# List printer in printer directory

Update-Printer -PrinterName 'NNPTC1-2400-P209-MFP578-012314' -ListInDirectory
```

## Examples

```powershell
# Example 1 - set the print driver and print processor for a specific printer

Update-Printer -PrinterName 'NNPTC1-2400-P209-MFP578-012314' -UpdateDriver -UpdateProcessor


# Example 2 - run all printers against their stored properties without committing any actions. Use a custom filepath.

Update-Printer -ImportSettings -PrinterPropertiesXML 'C:\Program Files\Tools\Printers\PrinterSettings.xml' -WhatIf
```

## Get-Help