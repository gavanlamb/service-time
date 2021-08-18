using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Time.DbContext.Extensions
{
    public static class ServiceCollection
    {
        public static IServiceCollection AddTimeRepository(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            services.AddDbContext<TimeDbContext>(options => options.UseNpgsql(configuration.GetConnectionString("Default")));
            services.Configure<Database>(configuration.GetSection("Database"));
            return services;
        }

        public static IServiceCollection AddTimeDbContextForMigrations(
            this IServiceCollection services,
            IConfiguration configuration,
            string migrationsAssembly)
        {
            services.AddDbContext<TimeDbContext>(options => options.UseNpgsql(
                    configuration.GetConnectionString("Default"),
     o => o.MigrationsAssembly(migrationsAssembly)),
                ServiceLifetime.Singleton);
            services.Configure<Database>(configuration.GetSection("Database"));
            return services;
        }
    }
}