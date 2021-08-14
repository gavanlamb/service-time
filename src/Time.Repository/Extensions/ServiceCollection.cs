using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Time.Repository.Extensions
{
    public static class ServiceCollection
    {
        public static IServiceCollection AddTimeRepository(
            this IServiceCollection services,
            string timeDbConnectionString)
        {
            services.AddDbContext<TimeDbContext>(options => options.UseNpgsql(timeDbConnectionString));
            return services;
        }
        
        
        public static IServiceCollection AddTimeDbContextForMigrations(
            this IServiceCollection services,
            string migrationsAssembly,
            string timeDbConnectionString)
        {
            services.AddDbContext<TimeDbContext>(options => options.UseNpgsql(timeDbConnectionString,
                o => o.MigrationsAssembly(migrationsAssembly)),
                ServiceLifetime.Singleton);
            return services;
        }
    }
}