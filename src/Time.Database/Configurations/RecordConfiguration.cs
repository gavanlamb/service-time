using System.Diagnostics.CodeAnalysis;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Time.Database.Entities;

namespace Time.Database.Configurations;

[ExcludeFromCodeCoverage]
public class RecordConfiguration : IEntityTypeConfiguration<Record>
{
    public void Configure(
        EntityTypeBuilder<Record> builder)
    {
        builder.HasIndex(p => p.UserId);
        builder.Property(p => p.UserId).IsRequired();
            
        builder.Property(p => p.Name).IsRequired();
    }
}