using System;
using System.Collections.Generic;

namespace NNTPBlueTool.Models;

public partial class AccountManagement
{
    public int Id { get; set; }

    public DateTime Date { get; set; }

    public string ImpersonatingUser { get; set; } = null!;

    public string ServiceAccount { get; set; } = null!;

    public string? Severity { get; set; }

    public string Message { get; set; } = null!;
}
