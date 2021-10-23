using System;

namespace Time.Database.Entities
{
    public class Record
    {
        public long Id { get; set; }
        
        public string UserId { get; set; }

        public string Name { get; set; }
        
        public DateTime Start { get; set; }
        
        public DateTime? End { get; set; }

        public TimeSpan? Duration { get; set; }
        
        public DateTime Created { get; set; }
        
        public DateTime? Modified { get; set; }
    }
}
