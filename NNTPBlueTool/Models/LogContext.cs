using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

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
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=sql.mydomain.local,9999;Database=ScriptLogs;User Id=wes;Password=1qaz!QAZ1qaz!QAZ;");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AccountManagement>(entity =>
        {
            entity.ToTable("AccountManagement", "log");

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
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
