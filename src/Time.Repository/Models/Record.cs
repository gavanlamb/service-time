using Microsoft.EntityFrameworkCore;

namespace Time.DbContext.Models
{
    [Index(nameof(UserId))]
    public class Record
    {
        public long Id { get; set; }
        
        public int UserId { get; set; }
        
        public int Name { get; set; }
        
        public int Start { get; set; }
        
        public int End { get; set; }
    }
}