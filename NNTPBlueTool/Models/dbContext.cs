using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace NNTPBlueTool.Models;

public partial class dbContext : DbContext
{
    public dbContext()
    {
    }

    public dbContext(DbContextOptions<dbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<PrsnlOrgAssignment> PrsnlOrgAssignments { get; set; }

    public virtual DbSet<PrsnlPerson> PrsnlPeople { get; set; }

    public virtual DbSet<User> Users { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=sql.mydomain.local,9999;Database=NP-NNPTC;User ID=wes;Password=1qaz!QAZ1qaz!QAZ;");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<PrsnlOrgAssignment>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK_PrsnlOrgAssignments_1");

            entity.ToTable("PrsnlOrgAssignments", "NP");

            entity.Property(e => e.Id)
                .ValueGeneratedNever()
                .HasColumnName("ID");
            entity.Property(e => e.ClassSection).HasMaxLength(15);
            entity.Property(e => e.DateFrom).HasColumnType("datetime");
            entity.Property(e => e.DateTo).HasColumnType("datetime");
            entity.Property(e => e.HierCode)
                .HasMaxLength(10)
                .IsFixedLength();
            entity.Property(e => e.Pid).HasColumnName("PID");

            entity.HasOne(d => d.PidNavigation).WithMany(p => p.PrsnlOrgAssignments)
                .HasForeignKey(d => d.Pid)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PrsnlOrgAssignments_PrsnlPeople");
        });

        modelBuilder.Entity<PrsnlPerson>(entity =>
        {
            entity.HasKey(e => e.Pid);

            entity.ToTable("PRSNL_PEOPLE", "NP");

            entity.Property(e => e.Pid)
                .ValueGeneratedNever()
                .HasColumnName("PID");
            entity.Property(e => e.BadgeId)
                .HasMaxLength(50)
                .HasColumnName("BadgeID");
            entity.Property(e => e.DepartureDate).HasColumnName("Departure_Date");
            entity.Property(e => e.Dodid)
                .HasMaxLength(50)
                .HasColumnName("DODID");
            entity.Property(e => e.EmailAddress).HasMaxLength(50);
            entity.Property(e => e.FirstName)
                .HasMaxLength(50)
                .HasColumnName("First_name");
            entity.Property(e => e.JobCode)
                .HasMaxLength(50)
                .HasColumnName("Job_Code");
            entity.Property(e => e.LastName)
                .HasMaxLength(50)
                .HasColumnName("Last_name");
            entity.Property(e => e.Office).HasMaxLength(50);
            entity.Property(e => e.Prd)
                .HasColumnType("datetime")
                .HasColumnName("PRD");
            entity.Property(e => e.Prefix).HasMaxLength(50);
            entity.Property(e => e.Prsgroup)
                .HasMaxLength(50)
                .HasColumnName("PRSGROUP");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("Users", "NP");

            entity.Property(e => e.UserId)
                .ValueGeneratedNever()
                .HasColumnName("UserID");
            entity.Property(e => e.Pid).HasColumnName("PID");
            entity.Property(e => e.WinLogonId)
                .HasMaxLength(50)
                .HasColumnName("WinLogonID");

            entity.HasOne(d => d.PidNavigation).WithMany(p => p.Users)
                .HasForeignKey(d => d.Pid)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Users_PRSNL_PEOPLE");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
