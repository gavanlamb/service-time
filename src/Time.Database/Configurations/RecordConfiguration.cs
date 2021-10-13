using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Time.Database.Entities;

namespace Time.Database.Configurations
{
    public class RecordConfiguration : IEntityTypeConfiguration<Record>
    {
        public void Configure(
            EntityTypeBuilder<Record> builder)
        {
            builder.ToTable("Record");
            builder.HasIndex(p => p.UserId);
        }
    }
}