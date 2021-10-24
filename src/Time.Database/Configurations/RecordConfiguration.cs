using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Time.Database.Entities;

namespace Time.Database.Configurations
{
    public class RecordConfiguration : IEntityTypeConfiguration<Record>
    {
        public void Configure(
            EntityTypeBuilder<Record> builder)
        {
            builder.HasIndex(p => p.UserId);
            builder.Property(p => p.UserId).IsRequired();
            
            builder.Property(p => p.Name).IsRequired();
            
            builder.Property(p => p.Created)
                .HasDefaultValueSql("current_timestamp at time zone 'UTC'")
                .ValueGeneratedOnAdd()
                .Metadata
                .SetAfterSaveBehavior(PropertySaveBehavior.Ignore);

            builder.Property(p => p.Modified)
                .HasDefaultValueSql("current_timestamp at time zone 'UTC'")
                .ValueGeneratedOnUpdate();
        }
    }
}