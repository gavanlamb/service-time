using System;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.EventLog;
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
            CreateCustomBuilder(args)
                .UseSerilog()
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
        
        public static IHostBuilder CreateCustomBuilder(string[] args)
        {
            var builder = new HostBuilder();

            builder.UseContentRoot(Directory.GetCurrentDirectory());
            builder.ConfigureHostConfiguration(config =>
            {
                config.AddEnvironmentVariables(prefix: "DOTNET_");
                if (args != null)
                {
                    config.AddCommandLine(args);
                }
            });

            builder
                .ConfigureAppConfiguration((hostingContext, config) =>
                {
                    var env = hostingContext.HostingEnvironment;

                    var reloadOnChange = hostingContext.Configuration.GetValue("hostBuilder:reloadConfigOnChange", defaultValue: true);

                    if (hostingContext.HostingEnvironment.EnvironmentName.StartsWith("Preview", StringComparison.InvariantCultureIgnoreCase))
                    {
                        config
                            .AddJsonFile("appsettings.json", true, reloadOnChange)
                            .AddJsonFile("appsettings.Preview.json", true, reloadOnChange);
                    }
                    else
                    {
                        config
                            .AddJsonFile("appsettings.json", true, reloadOnChange)
                            .AddJsonFile($"appsettings.{env.EnvironmentName}.json", true, reloadOnChange);
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

                    if (args != null)
                    {
                        config.AddCommandLine(args);
                    }

                    config.AddSystemsManager(configureSource =>
                    {
                        configureSource.Path = $"Time/{env}";
                        configureSource.ReloadAfter = TimeSpan.FromMinutes(5);
                        configureSource.Optional = true;
                    });
                })
                .ConfigureLogging((hostingContext, logging) =>
                {
                    var isWindows = RuntimeInformation.IsOSPlatform(OSPlatform.Windows);

                    // IMPORTANT: This needs to be added *before* configuration is loaded, this lets
                    // the defaults be overridden by the configuration.
                    if (isWindows)
                    {
                        // Default the EventLogLoggerProvider to warning or above
                        logging.AddFilter<EventLogLoggerProvider>(level => level >= LogLevel.Warning);
                    }

                    logging.AddConfiguration(hostingContext.Configuration.GetSection("Logging"));
                    logging.AddConsole();
                    logging.AddDebug();
                    logging.AddEventSourceLogger();

                    if (isWindows)
                    {
                        // Add the EventLogLoggerProvider on windows machines
                        logging.AddEventLog();
                    }

                    logging.Configure(options =>
                    {
                        options.ActivityTrackingOptions = ActivityTrackingOptions.SpanId
                                                          | ActivityTrackingOptions.TraceId
                                                          | ActivityTrackingOptions.ParentId;
                    });

                })
                .UseDefaultServiceProvider((context, options) =>
                {
                    bool isDevelopment = context.HostingEnvironment.IsDevelopment();
                    options.ValidateScopes = isDevelopment;
                    options.ValidateOnBuild = isDevelopment;
                });

            return builder;
        }
    }
}