using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using Time.DbContext.Configurations;
using Time.DbContext.Entities;

namespace Time.DbContext
{
    public class TimeDbContext : Microsoft.EntityFrameworkCore.DbContext
    {
        public TimeDbContext(
            DbContextOptions<TimeDbContext> options) : base(options)
        {
        }
        
        protected override void OnModelCreating(ModelBuilder modelBuilder)  
        {
            modelBuilder.ApplyConfiguration(new RecordConfiguration(
                new List<string>(),
                true));
        }  
        
        public DbSet<Record> Records { get; set; }
    }
}