using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Time.DbContext.Configurations;
using Time.DbContext.Entities;
using Time.DbContext.Options;

namespace Time.DbContext
{
    public class TimeDbContext : Microsoft.EntityFrameworkCore.DbContext
    {
        private readonly Seed _seedOptions;

        public TimeDbContext(
            DbContextOptions<TimeDbContext> options,
            IOptions<Seed> databaseOptions) : base(options)
        {
            _seedOptions = databaseOptions.Value;
        }
        
        protected override void OnModelCreating(ModelBuilder modelBuilder)  
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.ApplyConfiguration(new RecordConfiguration());
        }  
        
        public DbSet<Record> Records { get; set; }
    }
}