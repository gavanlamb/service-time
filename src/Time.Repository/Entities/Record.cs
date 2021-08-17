using System;
using Microsoft.EntityFrameworkCore;

namespace Time.DbContext.Entities
{
    [Index(nameof(UserId))]
    public class Record
    {
        public long Id { get; set; }
        
        public string UserId { get; set; }
        
        public string Name { get; set; }
        
        public DateTime Start { get; set; }
        
        public DateTime End { get; set; }
    }
}