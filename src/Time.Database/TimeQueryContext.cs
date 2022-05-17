using Microsoft.EntityFrameworkCore;

namespace Time.Database;

public class TimeQueryContext : TimeContext
{
    public TimeQueryContext(
        DbContextOptions<TimeQueryContext> options) : base(options)
    {
    }
}