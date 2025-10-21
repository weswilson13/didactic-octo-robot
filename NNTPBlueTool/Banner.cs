using Microsoft.Office.Interop.Word;

public class Banner
{
    static string NewLine(string ParentString, string ChildString="")
    {
        string newString = "\n";
        if (ParentString.TrimStart().StartsWith('-')) // a bullet should be indented
        {
            newString += "   ";
            if (!string.IsNullOrWhiteSpace(ChildString) && !ChildString.StartsWith('-')) { newString += " "; }
        }

        return newString;
    }
    public static void GovBanner()
    {

        string banner = @"
        
        You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.

        By using this IS (which includes any device attached to this IS), you consent to the following conditions:

        -The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations.

        -At any time, the USG may inspect and seize data stored on this IS.

        -Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose.

        -This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy.

        -Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details.
        ";

        string newString = "";
        int index;
        int maxLength = Global.WindowWidth;
        if (Console.IsOutputRedirected == false && Console.IsInputRedirected == false)
            maxLength = (int)((float)0.8 * Console.WindowWidth);

        var lines = banner.Split("\r");
        foreach (var line in lines)
        {
            if (line.Length > maxLength)
            {
                var rem = line.TrimStart();
                while (rem.Length > maxLength)
                {
                    // find the end of the word closest to our maxLength cutoff
                    // this will prevent splitting the string mid-word.
                    index = rem.IndexOf(' ', maxLength);
                    if (index != -1)
                    {
                        newString += NewLine(line, rem);
                        newString += rem.Substring(0, index);
                        rem = rem.Substring(index + 1).TrimStart();
                    }
                    else // index = -1, so we are last word of remaining line
                    {
                        newString += NewLine(line, rem);
                        break;
                    }
                } // end while loop - rem <= maxLength
                newString += NewLine(line, rem);
                newString += rem;
            }
            else // index = -1, so we are at the last word of the line
            {
                newString += NewLine(line);
                newString += line.TrimStart();
            }
        }

        Console.WriteLine(newString);
    }
    public static void PrintLogo()
    {
        Console.WriteLine(@"
  _   _   _   _   _______   _____                                                                   
 | \ | | | \ | | |__   __| |  __ \                                                                  
 |  \| | |  \| |    | |    | |__) |                                                                 
 | . ` | | . ` |    | |    |  ___/                                                                  
 | |\  | | |\  |    | |    | |                                                                      
 |_| \_| |_| \_|    |_|    |_|

                   _     __  __                 _     _______          _ 
     /\           | |   |  \/  |               | |   |__   __|        | |
    /  \   ___ ___| |_  | \  / | __ _ _ __ ___ | |_     | | ___   ___ | |
   / /\ \ / __/ __| __| | |\/| |/ _` | '_ ` _ \| __|    | |/ _ \ / _ \| |
  / ____ \ (_| (__| |_  | |  | | (_| | | | | | | |_     | | (_) | (_) | |
 /_/    \_\___\___|\__| |_|  |_|\__, |_| |_| |_|\__|    |_|\___/ \___/|_|
                                 __/ |                                   
                                |___/                                    
                                      
        ");
    }
}
