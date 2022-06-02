using System.Diagnostics.CodeAnalysis;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Time.Database.Options;
using Time.Database.Seeds;

namespace Time.Database.Extensions;

[ExcludeFromCodeCoverage]
public static class ServiceCollection
{
    public static IServiceCollection AddTimeContext(
        this IServiceCollection services,
        IConfiguration configuration,
        ServiceLifetime contextLifeCycle = ServiceLifetime.Scoped)
    {
        services.AddDbContext<TimeCommandContext>(
            options =>
            {
                options.UseNpgsql(configuration.GetConnectionString("Command"));
                options.EnableSensitiveDataLogging();
                options.UseSnakeCaseNamingConvention();
            }, 
            contextLifeCycle);
        services.AddDbContext<TimeQueryContext>(
            options =>
            {
                options.UseNpgsql(configuration.GetConnectionString("Query"));
                options.EnableSensitiveDataLogging();
                options.UseSnakeCaseNamingConvention();
            }, 
            contextLifeCycle);
        services.AddScoped<Runner>();
        services.AddScoped<RecordSeeds>();
        services.Configure<Seed>(configuration.GetSection("Data"));
        return services;
    }
}