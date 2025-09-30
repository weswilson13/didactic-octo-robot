using System;
using System.Collections.Generic;
using System.Configuration;
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

    public virtual DbSet<PrsnlPerson> PrsnlPeople { get; set; }

    public virtual DbSet<User> Users { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            // Fallback for design-time tools, or throw if not configured
            optionsBuilder.UseSqlServer(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
        }
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<PrsnlPerson>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("PRSNL_PEOPLE", "NP");

            entity.Property(e => e.DepartureDate).HasColumnName("Departure_Date");
            entity.Property(e => e.FirstName)
                .HasMaxLength(10)
                .IsFixedLength()
                .HasColumnName("First_name");
            entity.Property(e => e.LastName)
                .HasMaxLength(10)
                .IsFixedLength()
                .HasColumnName("Last_name");
            entity.Property(e => e.Office)
                .HasMaxLength(10)
                .IsFixedLength();
            entity.Property(e => e.Pid).HasColumnName("PID");
            entity.Property(e => e.Prefix)
                .HasMaxLength(10)
                .IsFixedLength();
            entity.Property(e => e.Prsgroup)
                .HasMaxLength(10)
                .IsFixedLength()
                .HasColumnName("PRSGROUP");
            entity.Property(e => e.UserName)
                .HasMaxLength(15)
                .IsFixedLength();
            entity.Property(e => e.DODID)
                .HasMaxLength(10);
            entity.Property(e => e.BadgeId)
                .HasMaxLength(10);
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("Users", "NP");

            entity.Property(e => e.Pid).HasColumnName("PID");
            entity.Property(e => e.WinLogonId)
                .HasMaxLength(30)
                .IsFixedLength()
                .HasColumnName("WinLogonID");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
