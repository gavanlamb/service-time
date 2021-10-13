using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Time.Database.Options;
using Time.Database.Repositories;
using Time.Database.Seeds;

namespace Time.Database.Extensions
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
            services.AddScoped<IRecordRepository, RecordRepository>();
            services.Configure<Seed>(configuration.GetSection("Data"));
            return services;
        }
    }
}