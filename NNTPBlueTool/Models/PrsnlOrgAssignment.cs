using System;
using System.Collections.Generic;

namespace NNTPBlueTool.Models;

public partial class PrsnlOrgAssignment
{
    public int Id { get; set; }

    public int Pid { get; set; }

    public int HierarchyId { get; set; }

    public string HierCode { get; set; } = null!;

    public DateTime? DateTo { get; set; }

    public DateTime DateFrom { get; set; }

    public int? ClassSectionId { get; set; }

    public string? ClassSection { get; set; }

    public virtual PrsnlPerson PidNavigation { get; set; } = null!;
}
