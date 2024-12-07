# NNPTC NNTP Account Creation 

NNTP Account Creation is a multiple step process:

1. Generate a CSV file with pertinent user information
2. Create the Windows Accounts
3. Add the users to the required AD groups
4. Enable the accounts
5. Enforce smart card login

These steps are completed via 2 separate powershell scripts, one of which is executed on the NNPP network, the other on the NNTP network. 

## The Scripts

### GetTSCRUsers

This "tool" is comprised of multiple scripts/files and is executed on the NNPP network. At a high level, this step queries the NOTEPAD database and generates CSV files which are used on the NNTP network to create the accounts.

Located at 
> Z:\Shared\NNPTC\W_drives\ISD\Scripts\NewUserScripts

the actual scripts being executed are in the NNTPAccountCreation folder and are discussed below:
* **GetTSCRUsers.bat**
  * The batch file which initializes the user form
* **Form.ps1**
  * Uses .NET classes to build the User Interface, helping to control program logic
* **Get-TSCRUsers.ps1**
  * Executed when student accounts are needed
  * Uses .NET classes to connect to and query the NOTEPAD database
  * Generates 2 csv files, one for Active Directory account creation, the other for Seaware account creation
    * TSCR_AD.csv
    * TSCR_SW.csv
* **Get-TSCRInstructors.ps1**
  * Executed when staff accounts are needed
  * Uses .NET classes to connect to and query the NOTEPAD database
  * Generates 2 csv files, one for Active Directory account creation, the other for Seaware account creation
    * TSCR_Instructor_AD.csv
    * TSCR_Instructor_SW.csv

### Create-NNPTCStudents.ps1 / Create-NNPTCInstructors.ps1

Executed on the NNTP network following CSV generation.

Located at:
> \\\ptclw16p-bu01\W_drives\ISD\Scripts

these scripts create the Active directory accounts, add the users to the corresponding AD groups, and have the capability of scheduling account enablement and smart card enforcement.

## CSV Generation

Execute GetTSCRUsers.lnk. A user form will appear, which defaults to expect an NNPTC Class as input. The textbox has an *auto completion* feature which uses the NOTEPAD database (NP-NNPTC.NP.PrsnlClasses) as the source.

Executing the form in this manner will call Get-TSCRUsers.ps1, reading from the database view NP-NNPTC.NP.PrsnlSeawareUpload_V, filtering on the chosen class and storing select data in TSCR_AD.csv and TSCR_SW.csv.

Alternatively, the user may choose to generate a CSV by entering one or more IDs. The following combinations exist:

* Student by PID
* Student by DoDID
* Instructor by PID
* Instructor by DoDID

DoD ID is known by most sailors and easily found in the NOTEPAD web application. PID is available to Database Admins and users with additional permissions, as such DoDID may be the best choice for most users running this program for individual account creation.

Get-TSCRUsers.ps1 will be executed when Student is selected; Get-TSCRInstructors.ps1 will be executed for Instructor.

At the completion of either script, a couple things happen:
* the CSVs are copied to the NNTP (if the calling user has the appropriate permissions)
* the appropriate mail-merge files containing the NSAR and NNTP User Agreement Forms will open, at which time the user may print and distribute to the account requestors.  

## Creating Accounts

**Requires the *ActiveDirectory* Powershell module**

the script takes input from the corresponding .csv (TSCR_AD.csv for Students, TSCR_Instructor_AD.csv for staff), looping through each line and creating the account in Active Directory. 

**NOTE: the CSVs are required to be in the Scripts folder**