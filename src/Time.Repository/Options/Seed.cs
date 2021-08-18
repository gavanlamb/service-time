using System.Collections.Generic;

namespace Time.DbContext.Options
{
    public class Seed
    {
        public bool Run { get; set; }

        public List<string> UserIds { get; set; }
    }
}