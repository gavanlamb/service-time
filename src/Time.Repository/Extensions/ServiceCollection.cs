using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Time.DbContext.Options;
using Time.DbContext.Seeds;

namespace Time.DbContext.Extensions
{
    public static class ServiceCollection
    {
        public static IServiceCollection AddTimeRepository(
            this IServiceCollection services,
            IConfiguration configuration,
            ServiceLifetime contextLifeCycle = ServiceLifetime.Scoped)
        {
            services.AddDbContext<TimeDbContext>(options => options.UseNpgsql(configuration.GetConnectionString("Default")), contextLifeCycle);
            services.AddScoped<Runner>();
            services.AddScoped<RecordSeeds>();
            services.Configure<Seed>(configuration.GetSection("Data"));
            return services;
        }
    }
}