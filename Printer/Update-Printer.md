# NNPTC HP Printer Management Script - Update-Printer.ps1

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

Currently, the export creates a single XML file with all printers. Future updates may include functionality to specify individual files for each printer.

```powershell
# Export all configurations and all properties for all printers on the print server

Update-Printer -ExportSettings

# Export all configurations and specific properties for a single printer. Specify the output filepath.

Update-Printer -ExportSettings -Properties Config:DeviceIsMopier -PrinterName 'NNPTC1-2400-P209-MFP578-012314' -PrinterPropertiesXML C:\Tools\PrinterSettings.xml
```
![alt text](PrinterPropertiesXML.PNG)