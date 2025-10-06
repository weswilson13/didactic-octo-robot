using System;
using System.Collections.Generic;

namespace NNTPBlueTool.Models;

public partial class User
{
    public int Pid { get; set; }

    public string? WinLogonId { get; set; }

    public int UserId { get; set; }

    public virtual PrsnlPerson PidNavigation { get; set; } = null!;
}
