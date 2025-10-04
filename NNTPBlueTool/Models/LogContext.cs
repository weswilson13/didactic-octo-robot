using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using System.Configuration;

namespace NNTPBlueTool.Models;

public partial class LogContext : DbContext
{
    public LogContext()
    {
    }

    public LogContext(DbContextOptions<LogContext> options)
        : base(options)
    {
    }

    public virtual DbSet<AccountManagement> AccountManagements { get; set; }
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            // Fallback for design-time tools, or throw if not configured
            optionsBuilder.UseSqlServer(ConfigurationManager.ConnectionStrings["LogConnection"].ConnectionString);
        }
    }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AccountManagement>(entity =>
        {
            entity.ToTable("AccountManagement");

            entity.Property(e => e.Date).HasColumnType("datetime");
            entity.Property(e => e.ImpersonatingUser)
                .HasMaxLength(25)
                .IsFixedLength();
            entity.Property(e => e.ServiceAccount)
                .HasMaxLength(25)
                .IsFixedLength();
            entity.Property(e => e.Severity)
                .HasMaxLength(50)
                .IsFixedLength();
            entity.Property(e => e.Message).HasMaxLength(500);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
