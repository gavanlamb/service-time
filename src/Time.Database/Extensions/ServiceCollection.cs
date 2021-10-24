using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Time.Database.Options;
using Time.Database.Seeds;

namespace Time.Database.Extensions
{
    public static class ServiceCollection
    {
        public static IServiceCollection AddTimeContext(
            this IServiceCollection services,
            IConfiguration configuration,
            ServiceLifetime contextLifeCycle = ServiceLifetime.Scoped)
        {
            services.AddDbContext<TimeContext>(options => options.UseNpgsql(configuration.GetConnectionString("Default")), contextLifeCycle);
            services.AddScoped<Runner>();
            services.AddScoped<RecordSeeds>();
            services.Configure<Seed>(configuration.GetSection("Data"));
            return services;
        }
    }
}