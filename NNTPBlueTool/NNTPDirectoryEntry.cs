using System.Configuration;
using System.DirectoryServices;
using System.Diagnostics;
using System.Text.RegularExpressions;
using System.Management.Automation;
using System.Threading.Tasks.Dataflow;
using NNTPBlueTool.Models;
class NNTPDirectoryEntry
{
    public DirectoryEntry DirectoryEntry;
    public DirectoryEntry TargetEntry;
    public string Domain = ConfigurationManager.AppSettings["Domain"];
    public string Username;
    private string Password;
    public string? Firstname;
    public string? Lastname;
    public string? Email;
    public string sAMAccountName;
    public string UserPrincipalName;
    public string DisplayName;
    public string? DistinguishedName;
    public string? Role; // STAFF or STUDENT
    public string? RoleType; // NPS or NFAS
    public string? JobCode;
    public NNTPDirectoryEntry()
    {
    }
    public NNTPDirectoryEntry(DirectoryEntry RootDirectoryEntry)
    {
    }
    public NNTPDirectoryEntry(string Username, DirectoryEntry RootDirectoryEntry)
    {
        this.Username = Username;
        var directorySearcher = new DirectorySearcher(RootDirectoryEntry, $"(sAMAccountName={Username})");
        var searchResult = directorySearcher.FindOne();
        var userEntry = new DirectoryEntry();
        var userDomain = string.Empty;

        if (searchResult != null)
        {
            userEntry = searchResult.GetDirectoryEntry();

            // Extract domain from userPrincipalName (preferred) or distinguishedName
            try
            {
                userDomain = userEntry.Properties["userPrincipalName"].Value.ToString().Split('@')[1];
            }
            catch
            {
                var rg = new Regex(@"(?<=DC=)(\w+)");
                userDomain = string.Join('.', rg.Matches(RootDirectoryEntry.Properties["distinguishedName"].Value.ToString()));
            }
        }
        else
        {
            throw new Exception($"User {Username} not found in Active Directory.");
        }
        Password = GeneratePassword();
        DirectoryEntry = RootDirectoryEntry;
        TargetEntry = userEntry;
        Domain = userDomain;
    }

    public NNTPDirectoryEntry(PrsnlPerson person, DirectoryEntry RootDirectoryEntry)
    {
        if (string.IsNullOrWhiteSpace(person.UserName))
        {
            throw new Exception("Username is required.");
        }

        // Extract domain from root entry distinguishedName
        var rg = new Regex(@"(?<=DC=)(\w+)");
        Domain = string.Join('.', rg.Matches(RootDirectoryEntry.Properties["distinguishedName"].Value.ToString()));

        var directorySearcher = new DirectorySearcher(RootDirectoryEntry, $"(sAMAccountName={person.UserName?.Trim()})");
        var searchResult = directorySearcher.FindOne();

        Username = (searchResult?.Properties["sAMAccountName"][0]?.ToString() ?? person.UserName)?.Trim();
        Firstname = (searchResult?.Properties["givenName"][0]?.ToString() ?? person.FirstName)?.Trim();
        Lastname = (searchResult?.Properties["sn"][0]?.ToString() ?? person.LastName)?.Trim();
        Email = (searchResult?.Properties["mail"][0]?.ToString() ?? person.EmailAddress)?.Trim();
        sAMAccountName = Username;
        UserPrincipalName = Username + "@" + Domain;
        DisplayName = searchResult?.Properties["displayName"][0]?.ToString() ?? $"{person.Prefix} {person.LastName}, {person.FirstName}";
        Role = person.Prsgroup?.Trim(); // STAFF or STUDENT
        string? hierCode = person.PrsnlOrgAssignments.FirstOrDefault()?.HierCode?.Trim();
        if (Regex.Match(hierCode ?? "", @"[E,O]-|([A-D]-T)").Success)
        {
            RoleType = "NPS";
        }
        else if (Regex.Match(hierCode ?? "", @"A-").Success)
        {
            RoleType = "NFAS";
        }
        else
        {
            throw new Exception("Invalid HierCode. Must start with E-, O-, A-, A-T, B-T, C-T, or D-T.");
        }

        DistinguishedName = GetDefaultOU(); // get default OU based on Role and RoleType
        Password = GeneratePassword();  
        
        DirectoryEntry = RootDirectoryEntry;
        TargetEntry = searchResult?.GetDirectoryEntry() ?? null;
    }
    public void UnlockAccount()
    {
        TargetEntry.Properties["lockoutTime"].Value = 0;
        TargetEntry.CommitChanges();
    }
    public void EnableAccount()
    {
        int oldUAC = (int)TargetEntry.Properties["userAccountControl"].Value;
        bool enableAccount = (oldUAC & (int)UserAccountControl.ACCOUNTDISABLE) != 0;
        if (enableAccount)
        {
            TargetEntry.Properties["userAccountControl"].Value = oldUAC & ~(int)UserAccountControl.ACCOUNTDISABLE;
            TargetEntry.CommitChanges();
            Console.WriteLine($"Enabled account {DirectoryEntry.Properties["distinguishedName"].Value}");
        }
    }
    public void ResetPassword(string NewPassword = "")
    {
        if (string.IsNullOrWhiteSpace(NewPassword))
        {
            string username = TargetEntry.Name;
            string lastThree = username.Substring(username.Length - 3);
            NewPassword = $"Gonavybeatarmy{lastThree}!";
        }
        try
        {
            TargetEntry.Invoke("SetPassword", NewPassword);
        }
        catch
        {
            throw;
        }
    }
    public void ExpirePassword()
    {
        try
        {
            TargetEntry.Properties["pwdLastSet"].Value = 0;
            TargetEntry.CommitChanges();
        }
        catch
        {
            throw;
        }
    }
    public void MoveUser(string NewParentOU = null)
    {
        string nfasStudents = DefaultOUs["NFAS-Students"];
        string npsStudents = DefaultOUs["NPS-Students"];
        string nfasInstructors = DefaultOUs["NFAS-Instructors"];
        string npsInstructors = DefaultOUs["NPS-Instructors"];

        string message = "Choose from one of the following destination OUs:\n\n" +
                         $"1. NFAS-Students ({nfasStudents})\n" +
                         $"2. NPS-Students ({npsStudents})\n" +
                         $"3. NFAS-Instructors ({nfasInstructors})\n" +
                         $"4. NPS-Instructors ({npsInstructors})\n" +
                         "5. Other\n\n" +
                         "Enter 1 - 5: ";

        Console.WriteLine(message);
        string choice = Console.ReadLine();
        string targetOU = choice switch
        {
            "1" => nfasStudents,
            "2" => npsStudents,
            "3" => nfasInstructors,
            "4" => npsInstructors,
            "5" => FindOU(),
            _ => throw new Exception("Invalid choice. Must be 1, 2, 3, 4, or 5.")
        };
        Console.WriteLine($"Moving user {Username} to {targetOU}");

        // find the parent OU in the context of the root directory entry
        DirectorySearcher parentSearcher = new DirectorySearcher(DirectoryEntry, $"(distinguishedName={targetOU})");
        var parentResult = parentSearcher.FindOne();
        var parentEntry = parentResult.GetDirectoryEntry();

        // move the user to the new OU
        TargetEntry.MoveTo(parentEntry);
        TargetEntry.CommitChanges();

        Console.WriteLine($"Successfully moved user {Username} to {targetOU}");

        // clean up
        parentSearcher.Dispose();
        parentEntry.Dispose();
    }
    public NNTPDirectoryEntry CreateUser(string ParentOU = null)
    {
        string domain = string.Join('.', DirectoryEntry.Properties["distinguishedName"].Value.ToString().Replace("DC=", "").Split(','));
        string parentOU = ParentOU ?? $"CN=Users,{DirectoryEntry.Properties["distinguishedName"].Value}";

        // find the parent OU in the context of the root directory entry
        DirectorySearcher parentSearcher = new DirectorySearcher(DirectoryEntry, $"(distinguishedName={parentOU})");
        var parentResult = parentSearcher.FindOne();
        var parentEntry = parentResult.GetDirectoryEntry();

        // create the user and move it to the correct OU
        using (var newUser = DirectoryEntry.Children.Add($"CN={Username}", "user"))
        {
            newUser.CommitChanges();
            newUser.MoveTo(parentEntry);
            newUser.CommitChanges();

            // set the identity properties
            newUser.Properties["sAMAccountName"].Value = sAMAccountName ?? Username;
            newUser.CommitChanges();
            newUser.Properties["userPrincipalName"].Value = UserPrincipalName ?? $"{Username}@{domain}";
            newUser.CommitChanges();

            // set the name properties
            newUser.Properties["givenName"].Value = Firstname;
            newUser.Properties["sn"].Value = Lastname;
            newUser.Properties["displayName"].Value = DisplayName ?? $"{Firstname} {Lastname}" ?? Username;
            newUser.Properties["mail"].Value = Email ?? $"{Username}@{domain}";
            newUser.CommitChanges();

            // set account expiration to 30 days from now
            newUser.Properties["accountExpires"].Value = DateTime.Today.AddDays(30).ToFileTime().ToString();
            newUser.CommitChanges();

            // set the password
            newUser.Invoke("SetPassword", Password);
            newUser.CommitChanges();

            Console.WriteLine($"Created user {Username} in domain {domain}");
        }

        // clean up
        parentSearcher.Dispose();
        parentEntry.Dispose();

        TargetEntry = new DirectorySearcher(DirectoryEntry, $"(sAMAccountName={Username})").FindOne().GetDirectoryEntry();
        return new NNTPDirectoryEntry(TargetEntry);
    }
    private string GeneratePassword(string Password="") // generate a default password
    {
        if (Role == "STUDENT")
        {
            string username = Username;
            string lastThree = username.Substring(username.Length - 3);
            return $"Gonavybeatarmy{lastThree}!";
        }
        else if (Role == "STAFF")
        {
            return "Gonavybeatarmy123!";
        }
        else
        {
            if (string.IsNullOrWhiteSpace(Password))
            {
                throw new Exception("User Role is not STUDENT or STAFF, and no password was provided. Cannot generate default password.");
            }
            return Password;
        }
    }
    public void GetUser() // return sAMAccountName from powershell Out-GridView selection
    {
        string domain = DirectoryEntry.Path.Split('/')[2];

        var startInfo = new ProcessStartInfo()
        {
            FileName = "powershell.exe",
            Arguments = $"-NoProfile -ExecutionPolicy AllSigned -File \"GetDirectoryInfo.ps1\" -Domain {domain} -Username {Username} -Action ViewUser",
            UseShellExecute = false,
            RedirectStandardOutput = true
        };
        var proc = Process.Start(startInfo);
        proc.WaitForExit();
    }
    private Boolean TestForUser(string Username) // check if user exists in AD
    {
        DirectoryEntry directoryEntry = new DirectoryEntry($"WinNT://{Domain}/{Username},user");
        if (string.IsNullOrWhiteSpace(directoryEntry.Path)) // user does not exist
            return false;

        return true; // user exists
    }
    public string FindOU() // return OU distinguishedName from powershell Out-GridView selection
    {
        string domain = DirectoryEntry.Path.Split('/')[2];

        var startInfo = new ProcessStartInfo()
        {
            FileName = "powershell.exe",
            Arguments = $"-NoProfile -ExecutionPolicy AllSigned -File \"GetDirectoryInfo.ps1\" -Domain {domain} -Action GetOUs",
            UseShellExecute = false,
            RedirectStandardOutput = true
        };
        var proc = Process.Start(startInfo);
        proc.WaitForExit();
        var ou = proc.StandardOutput.ReadToEnd().ReplaceLineEndings().Trim();

        if (string.IsNullOrWhiteSpace(ou))
        {
            throw new Exception("No OU selected");
        }
        return ou;
    }
    private string GetDefaultOU() // return default OU based on user type (e.g., student, instructor)
    {
        string key = RoleType;
        if (Role == "STUDENT")
        {
            key += "-Students";
        }
        else if (Role == "STAFF")
        {
            key += "-Instructors";
        }

        if (!DefaultOUs.ContainsKey(key))
        {
            return null;
        }

        return DefaultOUs[key];
    }
    public void SetGroupMemberships() // set group memberships based on user type (e.g., student, instructor)
    {
        List<string> keys = new List<string>();

        string key = RoleType;
        if (Role == "STUDENT")
        {
            key += "-Students";
            if (!string.IsNullOrWhiteSpace(JobCode))
            {
                if (JobCode.Contains("RAN") || JobCode.Contains("UK")) // AUKUS student
                {
                    keys.Add("AUKUS");
                }
            }
        }
        else if (Role == "STAFF")
        {
            key += "-Instructors";
            keys.Add("All-Instructors");
        }

        if (GroupMemberships.ContainsKey(key))
        {
            keys.Add(key);
        }
        else
        {
            Console.WriteLine($"No group membership found for key {key}");
        }

        foreach (var k in keys)
        {
            AddToGroup(GroupMemberships[k]);
        }

    }
    private void AddToGroup(string GroupDN) // add user to group based on key
    {
        DirectorySearcher groupSearcher = new DirectorySearcher(DirectoryEntry, $"(distinguishedName={GroupDN})");
        var groupResult = groupSearcher.FindOne();
        var groupEntry = groupResult.GetDirectoryEntry();

        if (groupEntry.Properties["member"].Contains(TargetEntry.Properties["distinguishedName"].Value))
        {
            Console.WriteLine($"User {Username} is already a member of group {GroupDN}");
            return;
        }

        groupEntry.Properties["member"].Add(TargetEntry.Properties["distinguishedName"].Value);
        groupEntry.CommitChanges();
        Console.WriteLine($"Added user {Username} to group {GroupDN}");

        // clean up
        groupSearcher.Dispose();
        groupEntry.Dispose();
    }
    private Dictionary<string, string> DefaultOUs = new Dictionary<string, string>()
    {
        { "NFAS-Students", "OU=NFAS-Students,OU=NNPTC,OU=NNTP Users,DC=MYDOMAIN,DC=LOCAL" },
        { "NPS-Students", "OU=NPS-Students,OU=NNPTC,OU=NNTP Users,DC=MYDOMAIN,DC=LOCAL" },
        { "NFAS-Instructors", "OU=NFAS-Instructors,OU=NNPTC,OU=NNTP Users,DC=MYDOMAIN,DC=LOCAL" },
        { "NPS-Instructors", "OU=NPS-Instructors,OU=NNPTC,OU=NNTP Users,DC=MYDOMAIN,DC=LOCAL" }
    };
    private Dictionary<string, string> GroupMemberships = new Dictionary<string, string>()
    {
        { "NFAS-Students", "CN=NNPTC-NFAS-Students,OU=NNTP Groups,DC=MYDOMAIN,DC=LOCAL" },
        { "NPS-Students", "CN=NNPTC-NPS-Students,OU=NNTP Groups,DC=MYDOMAIN,DC=LOCAL" },
        { "NFAS-Instructors", "CN=NNPTC-NFAS-Instructors,OU=NNTP Groups,DC=MYDOMAIN,DC=LOCAL" },
        { "NPS-Instructors", "CN=NNPTC-NPS-Instructors,OU=NNTP Groups,DC=MYDOMAIN,DC=LOCAL" },
        { "All-Instructors", "CN=NNTP-TC-NNPTC,OU=NNTP Groups,DC=MYDOMAIN,DC=LOCAL" },
        { "AUKUS", "CN=AUKUS,OU=Permissions Model,OU=NNTP Groups,DC=MYDOMAIN,DC=LOCAL" }
    };
    [Flags]
    public enum UserAccountControl
    {
        /// <summary>
        /// The logon script is executed. 
        ///</summary>
        SCRIPT = 1,

        /// <summary>
        /// The user account is disabled. 
        ///</summary>
        ACCOUNTDISABLE = 2,

        /// <summary>
        /// The home directory is required. 
        ///</summary>
        HOMEDIR_REQUIRED = 8,

        /// <summary>
        /// The account is currently locked out. 
        ///</summary>
        LOCKOUT = 16,

        /// <summary>
        /// No password is required. 
        ///</summary>
        PASSWD_NOTREQD = 32,

        /// <summary>
        /// The user cannot change the password. 
        ///</summary>
        /// <remarks>
        /// Note:  You cannot assign the permission settings of PASSWD_CANT_CHANGE by directly modifying the UserAccountControl attribute. 
        /// For more information and a code example that shows how to prevent a user from changing the password, see User Cannot Change Password.
        /// </remarks>
        PASSWD_CANT_CHANGE = 64,

        /// <summary>
        /// The user can send an encrypted password. 
        ///</summary>
        ENCRYPTED_TEXT_PASSWORD_ALLOWED = 128,

        /// <summary>
        /// This is an account for users whose primary account is in another domain. This account provides user access to this domain, but not 
        /// to any domain that trusts this domain. Also known as a local user account. 
        ///</summary>
        TEMP_DUPLICATE_ACCOUNT = 256,

        /// <summary>
        /// This is a default account type that represents a typical user. 
        ///</summary>
        NORMAL_ACCOUNT = 512,

        /// <summary>
        /// This is a permit to trust account for a system domain that trusts other domains. 
        ///</summary>
        INTERDOMAIN_TRUST_ACCOUNT = 2048,

        /// <summary>
        /// This is a computer account for a computer that is a member of this domain. 
        ///</summary>
        WORKSTATION_TRUST_ACCOUNT = 4096,

        /// <summary>
        /// This is a computer account for a system backup domain controller that is a member of this domain. 
        ///</summary>
        SERVER_TRUST_ACCOUNT = 8192,

        Unused1 = 16384,

        Unused2 = 32768,

        /// <summary>
        /// The password for this account will never expire. 
        ///</summary>
        DONT_EXPIRE_PASSWD = 65536,

        /// <summary>
        /// This is an MNS logon account. 
        ///</summary>
        MNS_LOGON_ACCOUNT = 131072,

        /// <summary>
        /// The user must log on using a smart card. 
        ///</summary>
        SMARTCARD_REQUIRED = 262144,

        /// <summary>
        /// The service account (user or computer account), under which a service runs, is trusted for Kerberos delegation. Any such service 
        /// can impersonate a client requesting the service. 
        ///</summary>
        TRUSTED_FOR_DELEGATION = 524288,

        /// <summary>
        /// The security context of the user will not be delegated to a service even if the service account is set as trusted for Kerberos delegation. 
        ///</summary>
        NOT_DELEGATED = 1048576,

        /// <summary>
        /// Restrict this principal to use only Data Encryption Standard (DES) encryption types for keys. 
        ///</summary>
        USE_DES_KEY_ONLY = 2097152,

        /// <summary>
        /// This account does not require Kerberos pre-authentication for logon. 
        ///</summary>
        DONT_REQUIRE_PREAUTH = 4194304,

        /// <summary>
        /// The user password has expired. This flag is created by the system using data from the Pwd-Last-Set attribute and the domain policy. 
        ///</summary>
        PASSWORD_EXPIRED = 8388608,

        /// <summary>
        /// The account is enabled for delegation. This is a security-sensitive setting; accounts with this option enabled should be strictly 
        /// controlled. This setting enables a service running under the account to assume a client identity and authenticate as that user to 
        /// other remote servers on the network.
        ///</summary>
        TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION = 16777216,

        PARTIAL_SECRETS_ACCOUNT = 67108864,

        USE_AES_KEYS = 134217728
    }
}