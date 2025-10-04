using Microsoft.EntityFrameworkCore;
using NNTPBlueTool.Models;

public class Logger
{
    private LogContext logContext = new LogContext();
    private DateTime logDateTime= DateTime.Now;
    private string ImpersonatingUser = Environment.UserName;
    private string ServiceAccount;
    public Logger(LogContext logContext, string ServiceAccount)
    {
        this.logContext = logContext;
        this.ServiceAccount = ServiceAccount;
    }

    public void Log(string message)
    {
        try
        {
            logContext.AccountManagements.Add(new AccountManagement
            {
                Date = logDateTime,
                ImpersonatingUser = ImpersonatingUser,
                ServiceAccount = ServiceAccount,
                Message = message,
                Severity = "Info"
            });
            logContext.SaveChanges();
        }
        catch (DbUpdateException dbEx)
        {
            Console.WriteLine($"Database update error: {dbEx.Message}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"An error occurred while logging: {ex.Message}");
        }
    }
}