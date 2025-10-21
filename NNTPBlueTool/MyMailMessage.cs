using System.Net;
using System.Net.Mail;

public class MyMailMessage
{
    SmtpClient smtpClient;
    MailMessage mailMessage;
    public MyMailMessage(string From, string To, string Subject, string Body, string SmtpServer, string Username, string Password, int Port = 25, bool EnableSsl = true, string[] Attachments = null)
    {
        smtpClient = new SmtpClient(SmtpServer)
        {
            Port = Port,
            Credentials = new NetworkCredential(Username, Password),
            EnableSsl = EnableSsl,
        };

        mailMessage = new MailMessage
        {
            From = new MailAddress(From),
            Subject = Subject,
            Body = Body,
            IsBodyHtml = true,
        };

        // add attachments
        if (Attachments != null && Attachments.Length > 0)
        {
            foreach (var path in Attachments)
            {
                if (!string.IsNullOrEmpty(path))
                {
                    mailMessage.Attachments.Add(new Attachment(path));
                }
            }
        }

        mailMessage.To.Add(To);
    }

    public void SendMail()
    {
        try
        {
            smtpClient.Send(mailMessage);
        }
        catch (Exception e)
        {
            Console.WriteLine(e.Message);
        }
    }
}