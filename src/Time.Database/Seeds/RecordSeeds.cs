using System;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using Microsoft.Extensions.Options;
using Time.Database.Entities;
using Time.Database.Options;

namespace Time.Database.Seeds;

[ExcludeFromCodeCoverage]
public class RecordSeeds
{
    private readonly TimeCommandContext _db;
    private readonly Seed _seedOptions;
    public RecordSeeds(
        TimeCommandContext db,
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
                var start = DateTimeOffset.UtcNow.AddMinutes(-3306);
                var end = DateTimeOffset.UtcNow.AddMinutes(-3246);
                var duration = end - start;
                _db.Records.Add(new Record
                {
                    Name = "Project planning",
                    UserId = userId,
                    Start = start,
                    End = end,
                    Duration = duration,
                    Created = start,
                    Modified = end
                });
                    
                start = DateTimeOffset.UtcNow.AddMinutes(-3245);
                end = DateTimeOffset.UtcNow.AddMinutes(-3215);
                duration = end - start;
                _db.Records.Add(new Record
                {
                    Name = "Migration implementation",
                    UserId = userId,
                    Start = start,
                    End = end,
                    Duration = duration,
                    Created = start,
                    Modified = end
                });
                    
                start = DateTimeOffset.UtcNow.AddMinutes(-3214);
                end = DateTimeOffset.UtcNow.AddMinutes(-3179);
                duration = end - start;
                _db.Records.Add(new Record
                {
                    Name = "Seeding implementation",
                    UserId = userId,
                    Start = start,
                    End = end,
                    Duration = duration,
                    Created = start,
                    Modified = end
                });
                    
                start = DateTimeOffset.UtcNow.AddMinutes(-3178);
                end = DateTimeOffset.UtcNow.AddMinutes(-3118);
                duration = end - start;
                _db.Records.Add(new Record
                {
                    Name = "Logging implementation",
                    UserId = userId,
                    Start = start,
                    End = end,
                    Duration = duration,
                    Created = start,
                    Modified = end
                });
                    
                start = DateTimeOffset.UtcNow.AddMinutes(-3117);
                end = DateTimeOffset.UtcNow.AddMinutes(-3018);
                duration = end - start;
                _db.Records.Add(new Record
                {
                    Name = "Create scripts to create cognito user",
                    UserId = userId,
                    Start = start,
                    End = end,
                    Duration = duration,
                    Created = start,
                    Modified = end
                });

                _db.SaveChanges();
            }
        }
    }
}