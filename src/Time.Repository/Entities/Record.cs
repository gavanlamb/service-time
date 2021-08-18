using System;

namespace Time.DbContext.Entities
{
    public class Record
    {
        public Guid Id { get; set; }
        
        public string UserId { get; set; }
        
        public string Name { get; set; }
        
        public DateTime Start { get; set; }
        
        public DateTime End { get; set; }
    }
}