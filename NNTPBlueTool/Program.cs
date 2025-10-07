
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NNTPBlueTool.Models;
using System.Diagnostics;
using System.DirectoryServices;

void ClearConsole()

{
    if (Console.IsOutputRedirected == false && Console.IsInputRedirected == false)
    {
        Console.Clear();
    }
}

Logo.PrintLogo();

// Build configuration
var builder = new ConfigurationBuilder();
builder.SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
IConfiguration config = builder.Build();

// Read settings from configuration
string domain = config["AppSettings:Domain"] ?? throw new Exception("Domain is empty");
string domainUser = config["AppSettings:DomainUser"] ?? throw new Exception("DomainUser is empty");
string password = config["AppSettings:Password"] ?? throw new Exception("Password is empty");
string user = string.Empty;
PrsnlPerson dbUser = new PrsnlPerson();

string choice, usernameChoice = string.Empty;

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

// Dictionary for program choices
Dictionary<int, string> programChoices = new Dictionary<int,string> {
    { 1, "Reset password for existing user" },
    { 2, "Unlock and enable an existing user" },
    { 3, "Move user to different OU" },
    { 4, "Create new user" },
    { 5, "View User" }
};

// Dictionary for username input methods
Dictionary<int, string> usernameChoices = new Dictionary<int, string> {
    { 1, "Enter DoD ID" },
    { 2, "Enter Username" },
};

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

// Prompt for username input method
string enterUsernameMessage = "Scan the users NNPTC badge, or choose from the list below.\n\n" +
    string.Join("\n", usernameChoices.Select(c => $"{c.Key}. {c.Value}")) +
    $"\n\nEnter 1-{usernameChoices.Count}, or scan badge: ";

while (true)
{
    Console.WriteLine(enterUsernameMessage);
    usernameChoice = Console.ReadLine();
    if (!string.IsNullOrWhiteSpace(usernameChoice)) { break; }
    ClearConsole();
}
ClearConsole();

if (!usernameChoices.Keys.Contains(Convert.ToInt32(usernameChoice))) // use badge id to lookup username
{
    dbUser = dbContext.PrsnlPeople.Include(p => p.PrsnlOrgAssignments).FirstOrDefault(u => u.BadgeId == usernameChoice);

    if (dbUser == null)
    {
        Console.WriteLine($"No user found with Badge ID {usernameChoice}");
        return;
    }
}
else if (usernameChoice == "1") // enter dod id to lookup username
{
    Console.WriteLine("Enter the DoD ID:");
    var dodId = Console.ReadLine();
    dbUser = dbContext.PrsnlPeople.FirstOrDefault(u => u.Dodid == dodId);
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
else if (usernameChoice == "3") // search for a user
{
    var startInfo = new ProcessStartInfo()
    {
        FileName = "powershell.exe",
        Arguments = $"-NoProfile -ExecutionPolicy AllSigned -File \"GetDirectoryInfo.ps1\" -Domain {domain} -Action GetUsers",
        UseShellExecute = false,
        RedirectStandardOutput = true
    };
    var proc = Process.Start(startInfo);
    proc.WaitForExit();
    user = proc.StandardOutput.ReadToEnd().ReplaceLineEndings().Trim();

    if (string.IsNullOrWhiteSpace(user))
    {
        Console.WriteLine("No user selected");
        return;
    }
}

// Trim any whitespace from the username
user = dbUser.UserName ?? user;
user = user.Trim();

using (var rootEntry = new DirectoryEntry($"LDAP://{domain}", domainUser, password))
{
    // NNTPDirectoryEntry adminEntry = new NNTPDirectoryEntry(domainUser, rootEntry);

    // Console.WriteLine(adminEntry.DirectoryEntry.Properties["badPwdCount"].Value);

    Console.WriteLine($"Retrieving {user} from {rootEntry.Path}");

    NNTPDirectoryEntry userEntry = new NNTPDirectoryEntry();

    if (dbUser != null && !string.IsNullOrWhiteSpace(dbUser.UserName))
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
        userEntry.ResetPassword();
        userEntry.ExpirePassword();
        logger.Log($"Reset password for user {_distinctName}");
        return;
    }
    else if (choice == "2") // Enable only
    {
        userEntry.UnlockAccount();
        userEntry.EnableAccount();
        logger.Log($"Enabled user account {_distinctName}");
        return;
    }
    else if (choice == "3") // Move user to different OU
    {
        userEntry.MoveUser();
        logger.Log($"Moved user {_distinctName} to new OU");
        return;
    }
    else if (choice == "4") // Create new user
    {
        try
        {
            // NNTPDirectoryEntry newUserEntry = new NNTPDirectoryEntry(user, rootEntry);
            Console.WriteLine($"Creating new user {user} in domain {domain}");

            NNTPDirectoryEntry _user = userEntry.CreateUser(userEntry.DistinguishedName);
            logger.Log($"Created new user {_user.DistinguishedName}");

            // _user.SetGroupMemberships();
            userEntry.SetGroupMemberships();
            logger.Log($"Set group memberships for new user {_user.DistinguishedName}");
            return;
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex.Message);
            return;
        }
    }
    else if (choice == "5") // View user
    {
        userEntry.GetUser();
        logger.Log($"Viewed user {_distinctName}");
        return;
    }
}