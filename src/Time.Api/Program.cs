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
                    Console.WriteLine("Sources count:" + config.Sources.Count);
                    config.Sources.Clear();
                    Console.WriteLine("Sources count:" + config.Sources.Count);
                    Console.WriteLine("Cleared sources");

                    config.AddEnvironmentVariables(prefix: "DOTNET_");
                    if (args != null)
                    {
                        config.AddCommandLine(args);
                    }

                    var env = hostingContext.HostingEnvironment;
                    Console.WriteLine("Env:" + env.EnvironmentName);

                    var reloadOnChange = hostingContext.Configuration.GetValue("hostBuilder:reloadConfigOnChange", defaultValue: true);
                    Console.WriteLine("ReloadOnChange" + reloadOnChange.ToString());

                    if (hostingContext.HostingEnvironment.EnvironmentName.StartsWith("Preview", StringComparison.InvariantCultureIgnoreCase))
                    {
                        config
                            .AddJsonFile("appsettings.json", true, reloadOnChange)
                            .AddJsonFile("appsettings.Preview.json", true, reloadOnChange);
                        Console.WriteLine("Added:appsettings.json");
                        Console.WriteLine("Added:appsettings.Preview.json");
                    }
                    else
                    {
                        config
                            .AddJsonFile("appsettings.json", true, reloadOnChange)
                            .AddJsonFile($"appsettings.{env.EnvironmentName}.json", true, reloadOnChange);
                        Console.WriteLine("Added:appsettings.json");
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
                    
                    Console.WriteLine("Sources count:"+config.Sources.Count);

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