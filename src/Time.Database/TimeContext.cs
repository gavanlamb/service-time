using Microsoft.EntityFrameworkCore;
using Time.Database.Configurations;
using Time.Database.Entities;

namespace Time.Database
{
    public class TimeContext : DbContext
    {
        public TimeContext(
            DbContextOptions<TimeContext> options) : base(options)
        {
        }
        
        protected override void OnModelCreating(ModelBuilder modelBuilder)  
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.ApplyConfiguration(new RecordConfiguration());
        }
        
        public DbSet<Record> Records { get; set; }
    }
}