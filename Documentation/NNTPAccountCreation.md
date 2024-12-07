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
> Z:\Shared\NNPTC\W_drives\ISD\Scripts\NewUserScripts\GetTSCRUsers.lnk

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

CSV generation begins by executing GetTSCRUsers.lnk. A user form will appear, which defaults to expect an NNPTC Class as input. The textbox has an *auto completion* feature which uses the NOTEPAD database (NP-NNPTC.NP.PrsnlClasses) as the source. 

**NOTE: this tool is locally executed; as such, it is running in the context of the calling user and so a successful connection to the database is dependent upon the user having the appropriate permissions.**

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

**! Requires the *ActiveDirectory* Powershell module !**

Once the corresponding CSV has been created and exported to the NNTP network, the accounts may be created in Active Directory.

Execute one of the following, as appropriate:
> **Students:** \\\ptclw16p-bu01\w_drives\isd\Scripts\Create-TSCRStudents.ps1  
> **Instructors:** \\\ptclw16p-bu01\w_drives\isd\Scripts\Create-TSCRInstructors.ps1

The script takes input from the corresponding .csv (TSCR_AD.csv for Students, TSCR_Instructor_AD.csv for staff), looping through each line. If a user does not already exist in Active Directory, a new account is created and memberships added. If the user already exists the account is checked to ensure it has the correct description, naming convention, and temporary password.

(A student user may have an existing account if they are a rollback from a previous class)

**NOTE: the CSVs are required to be in the Scripts folder**

#### AD Group Memberships
***
* Students
  * NNTP.GOV/NNTP Groups/NNPTC/NFAS-Students
  * AUKUS
* Instructors
  * NFAS-Instructors
  * 

### Enabling Accounts and Enforcing Smart Card Logon

Once the accounts are created, the user has the option to schedule account enablement and smart card logon enforcement. This is dependent having the subsequent token issue scheduled.

If this is desired, the user will enter the date and time of the scheduled token issue. Generally it is done by class section. Separate scheduled tasks will be created on ptclw16p-bu01.

Unless specified, smart card enforcement will be scheduled to occur 2 hours following the scheduled account enablement task. 

## Required Database Permissions

The user must have **SELECT** permission on the following database objects:
* NP.PRSNL_PEOPLE
* NP.PrsnlOrgAssignments
* Core.Hierarchies