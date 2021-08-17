using System;
using System.Threading.Tasks;
using Amazon.CodeDeploy;
using Amazon.CodeDeploy.Model;
using Amazon.Lambda.Core;
using Expensely.Logging.Serilog;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Internal;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using Time.DbContext;
using Time.DbContext.Extensions;

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
            var db = scope.ServiceProvider.GetRequiredService<TimeDbContext>();
            db.Database.Migrate();
            
            
        }
        
        private static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureAppConfiguration((context, builder) =>
                {
                    var environmentName = context.HostingEnvironment.EnvironmentName;
                    builder.AddSystemsManager(configureSource =>
                    {
                        configureSource.Path = $"/Time/{environmentName}";
                        configureSource.ReloadAfter = TimeSpan.FromMinutes(5);
                        configureSource.Optional = true;
                    });
                })
                .UseSerilog()
                .ConfigureServices((hostContext, services) =>
                {
                    Logging.AddSerilog(hostContext.Configuration);

                    services.AddTimeDbContextForMigrations(
                        "Time.Migrations",
                        hostContext.Configuration.GetConnectionString("Default"));
                });
    }
}