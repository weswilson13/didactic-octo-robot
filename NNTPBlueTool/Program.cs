
using System.Reflection.Metadata.Ecma335;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Configuration.Json;
// using Microsoft.Extensions.Configuration.Binder;

// Build configuration
var builder = new ConfigurationBuilder();
builder.SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
IConfiguration config = builder.Build();

string domain = config["AppSettings:Domain"];
string domainUser = config["AppSettings:DomainUser"];
string password = config["AppSettings:Password"];

string message = "What would you like to do?\n" +
                 "1. Unlock and reset password for existing user\n" +
                 "2. Enable an existing user\n" +
                 "3. Create new user\n" +
                 "Enter 1, 2, or 3: ";
Console.WriteLine(message);
var choice = Console.ReadLine();

Console.WriteLine("Enter the username (sAMAccountName):");
var user = Console.ReadLine();

using (var rootEntry = new System.DirectoryServices.DirectoryEntry($"LDAP://{domain}", domainUser, password))
{
    NNTPDirectoryEntry adminEntry = new NNTPDirectoryEntry(domainUser, rootEntry);

    Console.WriteLine(adminEntry.DirectoryEntry.Properties["badPwdCount"].Value);

    Console.WriteLine($"Retrieving {user} from {rootEntry.Path}");

    NNTPDirectoryEntry userEntry = new NNTPDirectoryEntry(user, rootEntry);

    // Unlock the account
    userEntry.UnlockAccount();

    // Enable the account
    userEntry.EnableAccount();

    // Reset the password to the default value
    userEntry.ResetPassword();

    // Force user to change password at next logon
    userEntry.ExpirePassword();
}