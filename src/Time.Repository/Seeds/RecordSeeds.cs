using System;
using System.Linq;
using Microsoft.Extensions.Options;
using Time.DbContext.Entities;
using Time.DbContext.Options;

namespace Time.DbContext.Seeds
{
    public class RecordSeeds
    {
        private readonly TimeDbContext _db;
        private readonly Seed _seedOptions;
        public RecordSeeds(
            TimeDbContext db,
            IOptions<Seed> seedOptions)
        {
            _db = db;
            _seedOptions = seedOptions.Value;
        }

        public void Add()
        {
            foreach (var userId in _seedOptions.UserIds)
            {
                var userRecords = _db.Records.Any(r => r.UserId == userId);
                if (!userRecords)
                {
                    _db.Records.Add(new Record
                    {
                        Name = "Project planning",
                        UserId = userId,
                        Start = DateTime.UtcNow.AddMinutes(-3306),
                        End = DateTime.UtcNow.AddMinutes(-3246)
                    });
                    
                    _db.Records.Add(new Record
                    {
                        Name = "Migration implementation",
                        UserId = userId,
                        Start = DateTime.UtcNow.AddMinutes(-3245),
                        End = DateTime.UtcNow.AddMinutes(-3215)
                    });
                    
                    _db.Records.Add(new Record
                    {
                        Name = "Seeding implementation",
                        UserId = userId,
                        Start = DateTime.UtcNow.AddMinutes(-3214),
                        End = DateTime.UtcNow.AddMinutes(-3179)
                    });
                    
                    _db.Records.Add(new Record
                    {
                        Name = "Logging implementation",
                        UserId = userId,
                        Start = DateTime.UtcNow.AddMinutes(-3178),
                        End = DateTime.UtcNow.AddMinutes(-3118)
                    });
                    
                    _db.Records.Add(new Record
                    {
                        Name = "Create scripts to create cognito user",
                        UserId = userId,
                        Start = DateTime.UtcNow.AddMinutes(-3117),
                        End = DateTime.UtcNow.AddMinutes(-3018)
                    });

                    _db.SaveChanges();
                }
            }
        }
    }
}