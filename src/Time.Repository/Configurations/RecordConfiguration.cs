using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Time.DbContext.Entities;

namespace Time.DbContext.Configurations
{
    public class RecordConfiguration : IEntityTypeConfiguration<RecordEntity>
    {
        public void Configure(
            EntityTypeBuilder<RecordEntity> builder)
        {
            builder.ToTable("Record");
            builder.HasIndex(p => p.UserId);
        }
    }
}