using System;

namespace Time.Domain.Models
{
    public class Record
    {
        public long Id { get; init; }
        
        public string UserId { get; init; }

        public string Name { get; init; }
        
        public DateTimeOffset Start { get; init; }
        
        public DateTimeOffset? End { get; init; }

        public TimeSpan? Duration { get; init; }
    }
}