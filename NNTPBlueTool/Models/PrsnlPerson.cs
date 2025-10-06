using System;
using System.Collections.Generic;

namespace NNTPBlueTool.Models;

public partial class PrsnlPerson
{
    public int Pid { get; set; }

    public string? LastName { get; set; }

    public string? FirstName { get; set; }

    public string? Prsgroup { get; set; }

    public string? Prefix { get; set; }

    public DateOnly? DepartureDate { get; set; }

    public string? UserName { get; set; }

    public string? Office { get; set; }

    public string? Dodid { get; set; }

    public string? BadgeId { get; set; }

    public DateTime? Prd { get; set; }

    public string? EmailAddress { get; set; }
    public virtual ICollection<PrsnlOrgAssignment> PrsnlOrgAssignments { get; set; } = new List<PrsnlOrgAssignment>();

    public virtual ICollection<User> Users { get; set; } = new List<User>();
}
