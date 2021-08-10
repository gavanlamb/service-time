using System;
using System.Reflection;
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
                .ConfigureAppConfiguration((hostingContext, config) =>
                {
                    config.Sources.Clear();
                    Console.WriteLine("Cleared sources");

                    var env = hostingContext.HostingEnvironment;
                    Console.WriteLine("Env:" + env.EnvironmentName);

                    var reloadOnChange = hostingContext.Configuration.GetValue("hostBuilder:reloadConfigOnChange", defaultValue: true);
                    Console.WriteLine("ReloadOnChange" + reloadOnChange.ToString());

                    config.AddJsonFile("appsettings.json", optional: true, reloadOnChange: reloadOnChange);
                    Console.WriteLine("Added:appsettings.json");

                    if (hostingContext.HostingEnvironment.EnvironmentName.StartsWith("Preview", StringComparison.InvariantCultureIgnoreCase))
                    {
                        config.AddJsonFile("appsettings.Preview.json", true, reloadOnChange);
                        Console.WriteLine("Added:appsettings.Preview.json");
                    }
                    else
                    {
                        config.AddJsonFile($"appsettings.{env.EnvironmentName}.json", optional: true, reloadOnChange: reloadOnChange);
                        Console.WriteLine($"Added:appsettings.{env.EnvironmentName}.json");
                    }

                    if (env.IsDevelopment() && !string.IsNullOrEmpty(env.ApplicationName))
                    {
                        var appAssembly = Assembly.Load(new AssemblyName(env.ApplicationName));
                        if (appAssembly != null)
                        {
                            config.AddUserSecrets(appAssembly, optional: true);
                        }
                    }

                    config.AddEnvironmentVariables();
                    Console.WriteLine($"added:env variables");

                    if (args != null)
                    {
                        config.AddCommandLine(args);
                    }
                })
                .UseSerilog()
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
    }
}