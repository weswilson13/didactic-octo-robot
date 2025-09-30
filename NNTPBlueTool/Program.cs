
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NNTPBlueTool.Models;
using System.DirectoryServices;
using System.Linq;

// Build configuration
var builder = new ConfigurationBuilder();
builder.SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
IConfiguration config = builder.Build();

string domain = config["AppSettings:Domain"];
string domainUser = config["AppSettings:DomainUser"];
string password = config["AppSettings:Password"];
string user = string.Empty;
string choice = string.Empty;

var optionsBuilder = new DbContextOptionsBuilder<dbContext>();
optionsBuilder.UseSqlServer(config.GetConnectionString("DefaultConnection"));

var dbContext = new dbContext(optionsBuilder.Options);

while (true)
{
    string message = "What would you like to do?\n" +
                    "1. Unlock and reset password for existing user\n" +
                    "2. Enable an existing user\n" +
                    "3. Create new user\n" +
                    "Enter 1, 2, or 3: ";
    Console.WriteLine(message);
    choice = Console.ReadLine();
    if (new[] { "1", "2", "3" }.Contains(choice)) { break; }
}

string enterUsernameMessage = "Scan the users NNPTC badge, or choose from the list below.\n" +
                             "1. Enter DoD ID\n" +
                             "2. Enter username (sAMAccountName)\n"; 
Console.WriteLine(enterUsernameMessage);
var usernameChoice = Console.ReadLine();

if (!new[] { "1", "2" }.Contains(usernameChoice)) // use badge id to lookup username
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
        userEntry.EnableAccount();
        return;
    }
    else if (choice == "3") // Create new user
    {
        try
        {
            NNTPDirectoryEntry newUserEntry = new NNTPDirectoryEntry(user, "Gonavybeatarmy123!", rootEntry);
            Console.WriteLine($"Creating new user {user} in domain {domain}");
            // Additional code to set properties and commit changes would go here
            newUserEntry.CreateUser();
            return;
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex.Message);
            return;
        }
    }
}