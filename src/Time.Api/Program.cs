using System;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Serilog;

namespace Time.Api
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
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
                        configureSource.OnLoadException = exceptionContext =>
                        {
                            Console.WriteLine(exceptionContext.Exception);
                            Console.WriteLine(exceptionContext.Exception);
                            Console.WriteLine(exceptionContext.Exception);
                            Console.WriteLine(exceptionContext.Exception);
                            Console.WriteLine(exceptionContext.Exception);
                            Console.WriteLine(exceptionContext.Exception);
                            Console.WriteLine(exceptionContext.Exception);
                            Console.WriteLine(exceptionContext.Exception);
                            Console.WriteLine(exceptionContext.Exception);
                            Console.WriteLine(exceptionContext.Exception);
                        };
                    });
                })
                .UseSerilog()
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
    }
}