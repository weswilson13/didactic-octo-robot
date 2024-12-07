# ![NNPTC](NNPTC_Logo.jpg) NNPTC NNTP Student\Instructor Account Creation

NNTP Account Creation for Students\Instructors is a multiple step process. At high level, these are:

1. Generate a CSV file with pertinent user information
2. Create the Windows Accounts
3. Add the users to the required AD groups
4. Enable the accounts
5. Enforce smart card login

These steps are completed via 2 separate powershell scripts, the first of which is executed on the NNPP network, the second on the NNTP network.

## The Scripts

### 1. GetTSCRUsers

This "tool" is comprised of multiple scripts/files and is executed on the NNPP network. At a high level, this step queries the NOTEPAD database and generates a set of CSV files to be used in the second step, on the NNTP network, to create the accounts.

Launched from:
> Z:\Shared\NNPTC\W_drives\ISD\Scripts\NewUserScripts\GetTSCRUsers.lnk ![GetTSCRUsers](GetTSCRUsers_Shortcut.png)

the actual scripts being executed are in the NNTPAccountCreation folder and are described below:

* **GetTSCRUsers.bat**
  * The batch file which initializes the user form

* **Form.ps1**
  * Uses .NET classes to build the User Interface, helping to control program logic

  ![form](Form_Default.png)

* **Get-TSCRUsers.ps1**
  * Executed when student accounts are needed
  * Uses .NET classes to connect to and query the NOTEPAD database (*NP-NNPTC.NP.PrsnlSeawareUpload_V*)
  * Generates 2 csv files, one for Active Directory account creation, the other for Seaware account creation
    * TSCR_AD.csv
    * TSCR_SW.csv
  * Script help or additional details may be retrieved by executing the following from a powershell prompt:

  ```powershell
    Get-Help 'Z:\Shared\NNPTC\W_drives\ISD\Scripts\NewUserScripts\NNTPAccountCreation\Get-TSCRUsers.ps1' -Full
  ```

* **Get-TSCRInstructors.ps1**
  * Executed when instructor accounts are needed
  * Uses .NET classes to connect to and query the NOTEPAD database (*NP-NNPTC.NP.PRSNL_PEOPLE*)
  * Generates 2 csv files, one for Active Directory account creation, the other for Seaware account creation
    * TSCR_Instructor_AD.csv
    * TSCR_Instructor_SW.csv
  * Script help or additional details may be retrieved by executing the following from a powershell prompt:

  ```powershell
    Get-Help 'Z:\Shared\NNPTC\W_drives\ISD\Scripts\NewUserScripts\NNTPAccountCreation\Get-TSCRInstructors.ps1' -Full
  ```

* **??GetTSCRUsers.config??**
  * Application configuration settings and database connection string information

### 2. Create-NNPTCStudents.ps1 / Create-NNPTCInstructors.ps1

Executed on the NNTP network following CSV generation.

Located at:
> \\\ptclw16p-bu01\W_drives\ISD\Scripts

these scripts create the Active Directory accounts, add the users to the corresponding AD groups, and have the capability to schedule account enablement and smart card enforcement.

## CSV Generation (Step 1)

CSV generation is the first step in the account creation process and begins by executing *GetTSCRUsers.lnk*. A user form will appear, which defaults to expect an NNPTC Class as input. The textbox has an auto completion feature which uses the NOTEPAD database (*NP-NNPTC.NP.PrsnlClassSections*) as the data source.

##### NOTE: this tool is locally executed; as such, it is running in the context of the calling user and so a successful connection to and query of the database is dependent upon the user having the appropriate permissions (detailed below).

Executing the form in this manner will call *Get-TSCRUsers.ps1* with the chosen class as script input.

Alternatively, the user may choose to generate a CSV by entering one or more IDs. The following combinations exist:

* Student by PID
* Student by DoDID
* Instructor by PID
* Instructor by DoDID

![Lookup User by ID](GetTSCRUser_ByID.png)

DoD ID is known by most sailors and easily found in the NOTEPAD web application. PID is available to Database Admins and users with additional permissions; as such DoDID may be the best choice for most users running this program for ad-hoc account creation.

When ID's are used as script input (vice student class), the applicable script alters the WHERE clause of the T-SQL query to target DoDID or PID, as appropriate.

*Get-TSCRUsers.ps1* will be executed when Student is selected; *Get-TSCRInstructors.ps1* will be executed for Instructor.

At the completion of either script, a couple things happen:

* The following .csv files are created:
  * TSCR_AD.csv (TSCR_Instructor_AD.csv)
  * TSCR_SW.csv (TSCR_Instructor_SW.csv)
  * TSCR_*ClassSection*_AD.csv **(Student Class Only)**
  * TSCR_*ClassSection*_SW.csv **(Student Class Only)**

* All .csv files are created at:

> Z:\Shared\NNPTC\W_drives\ISD\ScriptLogs

* the CSVs are copied to the NNTP (if the calling user has the appropriate permissions)

* the appropriate Microsoft® Word mail-merge files containing the NSAR and NNTP User Agreement Forms will open, at which time the user may verify accuracy, print and distribute to the account requestors.  
  * Signed NSAR and NNTP User Agreement forms should be scanned and uploaded to [Sharepoint][formRepo] as soon as possible.

## Creating Accounts (Step 2)

**! This step requires the *ActiveDirectory* Powershell module !**

Once the corresponding CSV has been created and exported to the NNTP network, the accounts may be created in Active Directory.

Execute one of the following, as appropriate:
> **Students:** \\\ptclw16p-bu01\w_drives\ISD\Scripts\Create-TSCRStudents.ps1  
> **Instructors:** \\\ptclw16p-bu01\w_drives\ISD\Scripts\Create-TSCRInstructors.ps1

The script takes input from the corresponding .csv (TSCR_AD.csv for Students, TSCR_Instructor_AD.csv for staff), looping through each line. If a user does not already exist in Active Directory, a new account is created and memberships added. If the user already exists the account is checked to ensure it has the correct description, naming convention, and temporary password.

(A student user may have an existing account if they are a rollback from a previous class. In this case, the AD Object description should be updated, at a minimum.)

##### NOTE: the CSVs are required to be in the Scripts folder

### AD Group Memberships:

* Students
  * NNTP.GOV/NNTP Groups/NNPTC/NFAS-Students
  * AUKUS
* Instructors
  * NFAS-Instructors (NPS-Instructors)
  * NNPTC-NFAS-TC (NNPTC-NPS-TC)

### Enabling Accounts and Enforcing Smart Card Logon:

**IMPORTANT: Accounts should not be enabled until the applicable forms have been signed and turned in to ISD**

Once the accounts are created, the user has the option to schedule account enablement and smart card logon enforcement. This is dependent having the subsequent token issue scheduled.

If this is desired, the user will enter the date and time of the scheduled token issue. This is generally broken up by class section. Separate scheduled tasks will be created on ptclw16p-bu01, as applicable.

Unless specified, smart card enforcement will be scheduled to occur 2 hours following the scheduled account enablement task.

## Prerequisites

### File System Permissions

On the **NNPP** network, the calling user needs to have *Read/Execute* permission on the script files, as well as *Write* permission to the CSV location in the Scriptlogs folder.

On the **NNTP** network, the calling user should have *Read/Execute* permission on the script files, as well as *Read* permission on the CSV files in the Scripts folder.

### Active Directory Permissions

The user executing the scripts on the NNTP network should have Create Object permission on the appropriate OU's, at a minimum.

Ideally, this step should be completed using an NNTP Server Admin account.

### Required Database Permissions

In order to execute the embedded T-SQL queries against the NOTEPAD databse, the calling user must have **SELECT** permission on the following database objects:

* NP.PrsnlSeawareUpload_V
* NP.Prsnl????????_V
* NP.PRSNL_PEOPLE
* NP.PrsnlOrgAssignments
* NP.PrsnlClasses
* Core.Hierarchies







[formRepo]: https://abc.de "Signed NSAR and NNTP User Agreements"