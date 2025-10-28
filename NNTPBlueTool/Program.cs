using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NNTPBlueTool.Models;
using System.Diagnostics;
using System.DirectoryServices;
using System.Text.RegularExpressions;

void ClearConsole()
{
    if (Console.IsOutputRedirected == false && Console.IsInputRedirected == false)
    {
        Console.Clear();
    }
}
void ExitApp()
{
    if (Console.IsOutputRedirected == false && Console.IsInputRedirected == false)
    {
        Console.WriteLine("Press 1 to return to the Main Menu or press 'Enter' to exit...");
        var key = Console.ReadKey();
        if (key.Key == ConsoleKey.Enter)
        {
            Environment.Exit(0);
        }
        else if (key.Key == ConsoleKey.D1)
        {
            ClearConsole();
            return;
        }
    }
}
void OpenMailMerge()
{
    // Test for the MailMerge folder in the users temp folder
    string mailMergeFolder = Global.MailMergeTarget;
    if (!System.IO.Path.Exists(mailMergeFolder))
    {
        Directory.CreateDirectory(mailMergeFolder);
    }

    // make a local copy of the word doc in the users temp folder
    Guid guid = Guid.NewGuid();
    FileInfo sourceFile = new FileInfo(Global.MailMergeSource);

    string destFile = System.IO.Path.Combine(mailMergeFolder, $"{guid.ToString()}.docx");
    System.IO.File.Copy(Global.MailMergeSource, destFile, true);

    Process.Start("explorer.exe", destFile);
}
static void OnProcessExit(object sender, EventArgs e)
{
    DeleteFiles();
}
static void DeleteFiles()
{
    try
    {
        Directory.Delete(Global.MailMergeTarget, true);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"An error occurred: {ex.Message}");
    }
}
void SetFilePaths(IConfiguration config, NNTPDirectoryEntry userEntry)
{
    // determine and set the file paths for the Seaware and AD Import files
    // use the Role and Job Code fields of the User Entry

    string mailMergeFile;
    string mailMergeDataFile;
    string seawareImportFile;

    string mailMergeFolder = config["FileSettings:MailMergeSourceFile_Location"] ?? throw new Exception("No mail merge data source LOCATION configured.");
    string mailMergeDataFolder = config["FileSettings:MailMergeDataSource_Location"] ?? throw new Exception("No mail merge data source LOCATION configured.");
    string seawareImportFolder = config["FileSettings:SeawareImportLocation"] ?? throw new Exception("No Seaware import LOCATION configured.");

    switch (userEntry.Role)
    {
        case "STAFF":
            mailMergeFile = config["FileSettings:MailMergeSourceFile_Instructor"] ?? throw new Exception("No mail merge data source (Instructor) configured.");
            mailMergeDataFile = config["FileSettings:MailMergeDataSource_Instructor"] ?? throw new Exception("No Mail Merge Data file (Instructor) configured.");
            seawareImportFile = config["FileSettings:SeawareImportFileName_Instructor"] ?? throw new Exception("No Seaware Import file (Instructor) configured.");
            break;

        case "STUDENT":
            if (Regex.Match(userEntry.JobCode ?? "", "RAN").Success) // if UK/RAN student, use the RAN Mail Merge File
            {
                mailMergeFile = config["FileSettings:MailMergSourceFile_StudentRAN"] ?? throw new Exception("No mail merge data source (RAN Student) configured.");
            }
            else // use the standard USN file
            {
                mailMergeFile = config["FileSettings:MailMergSourceFile_Student"] ?? throw new Exception("No mail merge data source (Student) configured.");
            }

            mailMergeDataFile = config["FileSettings:MailMergeDataSource_Student"] ?? throw new Exception("No Mail Merge Data file (Student) configured.");
            seawareImportFile = config["FileSettings:SeawareImportFileName_Student"] ?? throw new Exception("No Seaware Import file (Student) configured.");
            break;

        default:
            throw new Exception("Unable to determine File Settings. User Agreement Forms unable to be generated.");
    }
    // set global variables
    Global.MailMergeSource = Path.Combine(mailMergeFolder, mailMergeFile);
    Global.MailMergeTarget = System.IO.Path.Combine(Environment.GetEnvironmentVariable("TEMP"), "MailMerge");
    Global.SeawareCsvFile = Path.Combine(seawareImportFolder, seawareImportFile);
    Global.MailMergeDataSource = Path.Combine(mailMergeDataFolder, mailMergeDataFile);
}
void LogonBanner()
{
    Banner.GovBanner();

    if (Console.IsOutputRedirected == false && Console.IsInputRedirected == false)
    {
        Console.WriteLine("Press Enter to accept and continue");
        var key = Console.ReadKey();
        if (key.Key == ConsoleKey.Enter)
        {
            ClearConsole();
            return;
        }
        else
        {
            Environment.Exit(0);
        }
    }
}

if (Console.IsOutputRedirected == false && Console.IsInputRedirected == false)
    Console.WindowWidth = Global.WindowWidth;

LogonBanner();

AppDomain.CurrentDomain.ProcessExit += new EventHandler(OnProcessExit);

var config = Builder.BuildConfiguration("appsettings.json");

// Read settings from configuration
string domain = config["AppSettings:Domain"] ?? throw new Exception("Domain is empty");
string domainUser = config["AppSettings:DomainUser"] ?? throw new Exception("DomainUser is empty");
string password = config["AppSettings:Password"] ?? throw new Exception("Password is empty");

// mail specific settings
Global.SmtpServer = !string.IsNullOrWhiteSpace(config["MailSettings:SMTPServer"]) ? config["MailSettings:SMTPServer"] : throw new Exception("SMTP Server is not configured");
Global.SmtpPort = !string.IsNullOrWhiteSpace(config["MailSettings:Port"]) ? Convert.ToInt32(config["MailSettings:Port"]) : 25;
Global.MailBody = config["MailSettings:Body"] ?? "See attached user import files.";
Global.MailSubject = config["MailSettings:Subject"] ?? "New NNTP User Created";
Global.MailFrom = !string.IsNullOrWhiteSpace(config["MailSettings:From"]) ? config["MailSettings:From"] : "poweredge.t320.server@gmail.com";
Global.MailTo = !string.IsNullOrWhiteSpace(config["MailSettings:To"]) ? config["MailSettings:To"] : "poweredge.t320.server@gmail.com";

string user = string.Empty;

// Setup DbContext options
var optionsBuilder = new DbContextOptionsBuilder<dbContext>();
optionsBuilder.UseSqlServer(config.GetConnectionString("DefaultConnection"));

var logOptionsBuilder = new DbContextOptionsBuilder<LogContext>();
logOptionsBuilder.UseSqlServer(config.GetConnectionString("LogConnection"));

// Initialize DbContexts
var dbContext = new dbContext(optionsBuilder.Options);
var logContext = new LogContext(logOptionsBuilder.Options);

// Initialize Logger
Logger logger = new Logger(logContext, domainUser);
Logger appLogger = new Logger();

// Dictionary for program choices
Dictionary<int, string> programChoices = new Dictionary<int, string> {
    { 1, "Reset password for existing user" },
    { 2, "Unlock and enable an existing user" },
    { 3, "Move user to different OU" },
    { 4, "Create new user (from NOTEPAD data)" },
    { 5, "View User" },
    { 6, "Create User CSV" }
};

ProgramStart:

Banner.PrintLogo();

// Dictionary for username input methods
Dictionary<int, string> usernameChoices = new Dictionary<int, string> {
    { 1, "Enter DoD ID" },
    { 2, "Enter Username" }
};

string choice, usernameChoice = string.Empty;
PrsnlPerson? dbUser = null;

// Prompt for program choice
string message = "What would you like to do?\n\n" +
                 string.Join("\n", programChoices.Select(c => $"{c.Key}. {c.Value}")) +
                 $"\n\nEnter 1-{programChoices.Count}: ";

while (true)
{
    Console.WriteLine(message);
    choice = Console.ReadLine();
    if (programChoices.Select(c => c.Key.ToString()).Contains(choice)) { break; }
    ClearConsole();
}
ClearConsole();

// If the user didn't choose to create a new user, add the search option
if (programChoices[Convert.ToInt32(choice)] != "Create new user")
    usernameChoices.Add(3, "Search for User");

usernameChoices.Add(usernameChoices.Count + 1, "Back to Main Menu");

// Prompt for username input method
string enterUsernameMessage = "Scan the users NNPTC badge, or choose from the list below.\n\n" +
    string.Join("\n", usernameChoices.Select(c => $"{c.Key}. {c.Value}")) +
    $"\n\nEnter 1-{usernameChoices.Count}, or scan badge: ";

while (true)
{
    string actionTitle = programChoices[Convert.ToInt32(choice)];
    Console.WriteLine(actionTitle);
    Console.WriteLine(new string('=', actionTitle.Length) + "\n");
    Console.WriteLine(enterUsernameMessage);
    usernameChoice = Console.ReadLine();
    if (!string.IsNullOrWhiteSpace(usernameChoice)) { break; }
    ClearConsole();
}
ClearConsole();

if (!usernameChoices.Keys.Contains(Convert.ToInt32(usernameChoice))) // use badge id to lookup username
{
    dbUser = dbContext.PrsnlPeople.Include(p => p.PrsnlOrgAssignments).Include(p => p.Users).FirstOrDefault(u => u.BadgeId == usernameChoice);

    if (dbUser == null)
    {
        Console.WriteLine($"No user found with Badge ID {usernameChoice}");
        return;
    }

    user = dbUser.GetUsername();
}
else if (usernameChoice == "1") // enter dod id to lookup username
{
    Console.WriteLine("Enter the DoD ID:");
    var dodId = Console.ReadLine();
    dbUser = dbContext.PrsnlPeople.Include(p => p.PrsnlOrgAssignments).Include(p => p.Users).FirstOrDefault(u => u.Dodid == dodId);
    if (dbUser == null)
    {
        Console.WriteLine($"No user found with DoD ID {dodId}");
        return;
    }
}
else if (usernameChoice == "2") // enter username directly
{
    Console.WriteLine("Enter the username (sAMAccountName):");
    user = Console.ReadLine();

    // verify that we have a valid username before proceeding
    if (string.IsNullOrWhiteSpace(user))
    {
        Console.WriteLine("Username cannot be empty.");
        return;
    }
}
else if (usernameChoices[Convert.ToInt32(usernameChoice)] == "Search for User") // search for a user
{
    string output = "";
    if (choice == "6")
    {
        output = "-uID";
    }

    var startInfo = new ProcessStartInfo()
    {
        FileName = "powershell.exe",
        Arguments = $"-NoProfile -ExecutionPolicy AllSigned -File \"GetDirectoryInfo.ps1\" -Domain {domain} -Action GetUsers {output}",
        UseShellExecute = false,
        RedirectStandardOutput = true,
        RedirectStandardError = true
    };
    try
    {
        var proc = Process.Start(startInfo);
        if (proc.StandardError != null)
        {
            throw new Exception(proc.StandardError.ReadToEnd().ReplaceLineEndings().Trim());
        }
        proc.WaitForExit();
        if (proc.StandardOutput != null)
        {
            user = proc.StandardOutput.ReadToEnd().ReplaceLineEndings().Trim();
        }
    }
    catch (Exception e)
    {
        appLogger.LogError(e.Message, 5);
        Console.WriteLine("Failed to retrieve user\n");
        Console.WriteLine(e.Message + "\n");
    }

    if (string.IsNullOrWhiteSpace(user))
    {
        Console.WriteLine("No user selected");
        ExitApp();
        goto ProgramStart;
    }
}
else if (usernameChoices[Convert.ToInt32(usernameChoice)] == "Back to Main Menu")
{
    ClearConsole();
    goto ProgramStart;
}

// Trim any whitespace from the username
user = user.Trim();

if (choice == "6" && dbUser == null)
{
    dbUser = dbContext.PrsnlPeople.Include(p => p.PrsnlOrgAssignments).Include(p => p.Users).FirstOrDefault(u => u.Pid == Convert.ToInt32(user));
    if (dbUser == null)
    {
        Console.WriteLine($"No user found with PID {user}");
        ExitApp();
        goto ProgramStart;
    }
}
using (var rootEntry = new DirectoryEntry($"LDAP://{domain}", domainUser, password))
{
    Console.WriteLine($"Retrieving {user} from {rootEntry.Path}");

    NNTPDirectoryEntry userEntry = new NNTPDirectoryEntry();

    if (dbUser != null && !string.IsNullOrWhiteSpace(dbUser.GetUsername()))
    {
        userEntry = new NNTPDirectoryEntry(dbUser, rootEntry);
    }
    else
    {
        userEntry = new NNTPDirectoryEntry(user, rootEntry);
    }

    string _distinctName = userEntry.UserPrincipalName ?? userEntry.TargetEntry.Properties["distinguishedName"].Value.ToString();

    if (choice == "1") // Unlock and reset password
    {
        userEntry.UnlockAccount();
        Console.WriteLine($"Unlocked {_distinctName}");

        userEntry.ResetPassword();
        Console.WriteLine("Password reset to the default password.");

        userEntry.ExpirePassword();
        Console.WriteLine("User must change password at next logon.");

        logger.Log($"Reset password for user {_distinctName}");
        // return;
        ExitApp();
        goto ProgramStart;
    }
    else if (choice == "2") // Enable only
    {
        userEntry.UnlockAccount();
        userEntry.EnableAccount();
        logger.Log($"Enabled user account {_distinctName}");
        // return;
        ExitApp();
        goto ProgramStart;
    }
    else if (choice == "3") // Move user to different OU
    {
        userEntry.MoveUser();
        logger.Log($"Moved user {_distinctName} to new OU");
        // return;
        ExitApp();
        goto ProgramStart;
    }
    else if (choice == "4") // Create new user
    {
        try
        {
            // NNTPDirectoryEntry newUserEntry = new NNTPDirectoryEntry(user, rootEntry);
            Console.WriteLine($"Creating new user {user} in domain {domain}");

            NNTPDirectoryEntry _user = userEntry.CreateUser(userEntry.DistinguishedName);

            if (_user != null)
            {
                logger.Log($"Created new user {_user.DistinguishedName}");

                userEntry.SetGroupMemberships();
                logger.Log($"Set group memberships for new user {_user.DistinguishedName}");

                try
                {
                    SetFilePaths(config, userEntry);
                    
                    userEntry.WriteCSV();
                    logger.Log($"Created CSV for user {_distinctName}");
                    OpenMailMerge();
                }
                catch (System.IO.IOException e)
                {
                    appLogger.LogError(e.Message, 10);
                    Console.WriteLine($"{e.Message}\n\rClose any open Mail Merge files and/or verify the Source CSV isn't being used and try again.");
                    // throw new Exception($"{e.Message}\n\rClose any open Mail Merge files and/or verify the Source CSV isn't being used and try again.");
                }
            }

            ExitApp();
            goto ProgramStart;
        }
        catch (Exception ex)
        {
            appLogger.LogError(ex.Message, 15);
            Console.WriteLine(ex.Message);
            ExitApp();
            goto ProgramStart;
        }
    }
    else if (choice == "5") // View user
    {
        userEntry.GetUser();
        logger.Log($"Viewed user {_distinctName}");
        ExitApp();
        goto ProgramStart;
    }
    else if (choice == "6") // Create user CSV
    {
        try
        {
            SetFilePaths(config, userEntry);

            userEntry.WriteCSV();
            logger.Log($"Created CSV for user {_distinctName}");
            OpenMailMerge();
        }
        catch (System.IO.IOException e)
        {
            appLogger.LogError(e.Message, 20);
            Console.WriteLine($"{e.Message}\n\rClose any open Mail Merge files and/or verify the Source CSV isn't being used and try again.");
            // throw new Exception($"{e.Message}\n\rClose any open Mail Merge files and/or verify the Source CSV isn't being used and try again.");
        }
        ExitApp();
        goto ProgramStart;
    }
}