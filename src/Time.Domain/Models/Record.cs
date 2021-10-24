using System;

namespace Time.Domain.Models
{
    public class Record
    {
        public long Id { get; init; }
        
        public string UserId { get; init; }

        public string Name { get; init; }
        
        public DateTime Start { get; init; }
        
        public DateTime? End { get; init; }

        public TimeSpan? Duration { get; init; }
    }
}