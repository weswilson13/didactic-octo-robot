using System;
using System.Collections.Generic;

namespace NNTPBlueTool.Models;

public partial class PrsnlPerson
{
    public string? LastName { get; set; }

    public string? FirstName { get; set; }

    public string? Prsgroup { get; set; }

    public string? Prefix { get; set; }

    public DateOnly? DepartureDate { get; set; }

    public int? Pid { get; set; }

    public string? UserName { get; set; }

    public string? Office { get; set; }

    public string? DODID { get; set; }

    public string? BadgeId { get; set; }

}
