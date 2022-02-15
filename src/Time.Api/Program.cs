using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Serilog;

namespace Time.Api;

public class Program
{
    public static async Task Main(string[] args)
    {
        try
        {
            CreateHostBuilder(args).Build().Run();
        }
        catch (Exception exception)
        {
            Log.Fatal(exception, "Host terminated unexpectedly");
        }
        finally
        {
            Log.CloseAndFlush();
        }
    }

    private static IHostBuilder CreateHostBuilder(string[] args) =>
        Host.CreateDefaultBuilder(args)
            .ConfigureAppConfiguration((context, config) =>
            {
                var environmentName = context.HostingEnvironment.EnvironmentName;
                    
                if (environmentName.StartsWith("Preview", StringComparison.InvariantCultureIgnoreCase))
                {
                    config.AddJsonFile("appsettings.Preview.json", true, true);
                }

                config.AddSystemsManager(configureSource =>
                {
                    configureSource.Path = $"/Time/{environmentName}";
                    configureSource.ReloadAfter = TimeSpan.FromMinutes(5);
                    configureSource.Optional = true;
                });
            })
            .UseSerilog()
            .ConfigureWebHostDefaults(webBuilder =>
            {
                webBuilder.UseStartup<Startup>();
            });
}