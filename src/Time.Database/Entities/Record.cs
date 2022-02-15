using System;

namespace Time.Database.Entities;

public class Record
{
    public long Id { get; set; }
        
    public string UserId { get; set; }

    public string Name { get; set; }
        
    public DateTimeOffset Start { get; set; }
        
    public DateTimeOffset? End { get; set; }

    public TimeSpan? Duration { get; set; }
        
    public DateTimeOffset Created { get; set; }
        
    public DateTimeOffset? Modified { get; set; }
}