using Microsoft.EntityFrameworkCore;
using NNTPBlueTool.Models;
using System.Diagnostics;

public class Logger
{
    private LogContext logContext = new LogContext();
    private DateTime logDateTime= DateTime.Now;
    private string ImpersonatingUser = Environment.UserName;
    private string? ServiceAccount;
    public Logger()
    {
        
    }
    public void LogError(string message, short id = 0)
    {
        using (EventLog eventLog = new EventLog("Application"))
        {
            eventLog.Source = "Application";
            eventLog.WriteEntry(message, EventLogEntryType.Error, 58008, id);
        }
    }
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