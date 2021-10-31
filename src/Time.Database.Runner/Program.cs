﻿using System;
using System.Threading.Tasks;
using Amazon.CodeDeploy;
using Amazon.CodeDeploy.Model;
using Amazon.Lambda.Core;
using Expensely.Logging.Serilog;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using Time.Database;
using Time.Database.Extensions;
using Time.Database.Seeds;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.Json.JsonSerializer))]
namespace Time.Migrations
{
    public class Program
    {
        public static void Main(string[] args)
        {
            Run(args);
        }

        public async Task<PutLifecycleEventHookExecutionStatusResponse> Handler(
            PutLifecycleEventHookExecutionStatusRequest request, 
            ILambdaContext context)
        {
            try
            {
                Run(new string[0]);
                
                await PutLifecycleEventHookExecutionStatusAsync(
                    request.DeploymentId,
                    request.LifecycleEventHookExecutionId,
                    LifecycleEventStatus.Succeeded);
            }
            catch (Exception)
            {
                await PutLifecycleEventHookExecutionStatusAsync(
                    request.DeploymentId,
                    request.LifecycleEventHookExecutionId,
                    LifecycleEventStatus.Failed);
            }
        
            return new PutLifecycleEventHookExecutionStatusResponse();
        }
        
        private static async Task PutLifecycleEventHookExecutionStatusAsync(
            string deploymentId,
            string lifecycleEventHookExecutionId,
            LifecycleEventStatus status)
        {
            var codeDeployClient = new AmazonCodeDeployClient();
            var lifecycleRequest = new PutLifecycleEventHookExecutionStatusRequest
            {
                DeploymentId = deploymentId,
                LifecycleEventHookExecutionId = lifecycleEventHookExecutionId,
                Status = status
            };
            await codeDeployClient.PutLifecycleEventHookExecutionStatusAsync(lifecycleRequest);
        }

        private static void Run(string[] args)
        {
            var host = CreateHostBuilder(args).Build();

            using var scope = host.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<TimeContext>();
            db.Database.Migrate();
            
            var runner = scope.ServiceProvider.GetRequiredService<Runner>();
            runner.Run();
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
                .ConfigureServices((hostContext, services) =>
                {
                    services.AddOptions();

                    Logging.AddSerilog(hostContext.Configuration);

                    services.AddTimeContext(
                        hostContext.Configuration, 
                        ServiceLifetime.Singleton);
                });
    }
}