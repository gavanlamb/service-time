using Microsoft.EntityFrameworkCore;
using Time.DbContext.Models;

namespace Time.Repository
{
    public class TimeDbContext : Microsoft.EntityFrameworkCore.DbContext
    {
        public TimeDbContext(DbContextOptions<TimeDbContext> options)
            : base(options)
        {
        }
        
        public DbSet<Record> Records { get; set; }
    }
}