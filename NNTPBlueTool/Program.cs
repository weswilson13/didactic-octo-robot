
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NNTPBlueTool.Models;
using System.Diagnostics;
using System.DirectoryServices;
using System.Security.Cryptography;

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

string domain = config["AppSettings:Domain"] ?? throw new Exception("Domain is empty");
string domainUser = config["AppSettings:DomainUser"] ?? throw new Exception("DomainUser is empty");
string password = config["AppSettings:Password"] ?? throw new Exception("Password is empty");
string user = string.Empty;
string choice, usernameChoice = string.Empty;

var optionsBuilder = new DbContextOptionsBuilder<dbContext>();
optionsBuilder.UseSqlServer(config.GetConnectionString("DefaultConnection"));

var logOptionsBuilder = new DbContextOptionsBuilder<LogContext>();
logOptionsBuilder.UseSqlServer(config.GetConnectionString("LogConnection"));

var dbContext = new dbContext(optionsBuilder.Options);
var logContext = new LogContext(logOptionsBuilder.Options);

Logger logger = new Logger(logContext, domainUser);

while (true)
{
    string message = "What would you like to do?\n\n" +
                    "1. Reset password for existing user\n" +
                    "2. Unlock and enable an existing user\n" +
                    "3. Move user to different OU\n" +
                    "4. Create new user\n" +
                    "5. View User\n\n" +
                    "Enter 1, 2, 3, 4, or 5: ";
    Console.WriteLine(message);
    choice = Console.ReadLine();
    if (new[] { "1", "2", "3", "4", "5" }.Contains(choice)) { break; }
    ClearConsole();
}
ClearConsole();

while (true)
{
    string enterUsernameMessage = "Scan the users NNPTC badge, or choose from the list below.\n" +
                                 "1. Enter DoD ID\n" +
                                 "2. Enter username (sAMAccountName)\n" +
                                 "3. Search for a user";

    Console.WriteLine(enterUsernameMessage);
    usernameChoice = Console.ReadLine();
    if (!string.IsNullOrWhiteSpace(usernameChoice)) { break; }
    ClearConsole();
}
ClearConsole();

if (!new[] { "1", "2", "3" }.Contains(usernameChoice)) // use badge id to lookup username
{
    user = dbContext.PrsnlPeople.FirstOrDefault(u => u.BadgeId == usernameChoice)?.UserName;

    if (string.IsNullOrWhiteSpace(user))
    {
        Console.WriteLine($"No user found with Badge ID {usernameChoice}");
        return;
    }
}
else if (usernameChoice == "1") // enter dod id to lookup username
{
    Console.WriteLine("Enter the DoD ID:");
    var dodId = Console.ReadLine();
    user = dbContext.PrsnlPeople.FirstOrDefault(u => u.DODID == dodId)?.UserName;
    if (string.IsNullOrWhiteSpace(user))
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
user = user.Trim();

using (var rootEntry = new System.DirectoryServices.DirectoryEntry($"LDAP://{domain}", domainUser, password))
{
    NNTPDirectoryEntry adminEntry = new NNTPDirectoryEntry(domainUser, rootEntry);

    Console.WriteLine(adminEntry.DirectoryEntry.Properties["badPwdCount"].Value);

    Console.WriteLine($"Retrieving {user} from {rootEntry.Path}");

    NNTPDirectoryEntry userEntry = new NNTPDirectoryEntry(user, rootEntry);

    if (choice == "1") // Unlock and reset password
    {
        userEntry.UnlockAccount();
        userEntry.ResetPassword();
        userEntry.ExpirePassword();
        return;
    }
    else if (choice == "2") // Enable only
    {
        userEntry.UnlockAccount();
        userEntry.EnableAccount();
        return;
    }
    else if (choice == "3") // Move user to different OU
    {
        userEntry.MoveUser();
        return;
    }
    else if (choice == "4") // Create new user
    {
        try
        {
            NNTPDirectoryEntry newUserEntry = new NNTPDirectoryEntry(user, "Gonavybeatarmy123!", rootEntry);
            Console.WriteLine($"Creating new user {user} in domain {domain}");
            // Additional code to set properties and commit changes would go here
            DirectoryEntry _user = newUserEntry.CreateUser();
            logger.Log($"Created new user {_user.Properties["distinguishedName"].Value}");
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
        logger.Log($"Viewed user {user}");
        return;
    }
}