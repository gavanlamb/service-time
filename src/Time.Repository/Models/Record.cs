namespace Time.DbContext.Models
{
    public class Record
    {
        public int Id { get; set; }
        
        public int UserId { get; set; }
        
        public int Name { get; set; }
        
        public int Start { get; set; }
        
        public int End { get; set; }
    }
}