using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Time.DbContext.Entities;

namespace Time.DbContext.Configurations
{
    public class RecordConfiguration : IEntityTypeConfiguration<Record>
    {
        public void Configure(
            EntityTypeBuilder<Record> builder)
        {
            builder.HasIndex(p => p.UserId);
        }
    }
}