using Microsoft.EntityFrameworkCore;

namespace Time.Database;

public class TimeCommandContext : TimeContext
{
    public TimeCommandContext(
        DbContextOptions<TimeCommandContext> options) : base(options)
    {
    }
}