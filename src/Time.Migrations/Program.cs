using Expensely.Logging.Serilog;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Time.Repository.Extensions;

namespace Time.Migrations
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureServices((hostContext, services) =>
                {
                    Logging.AddSerilog(hostContext.Configuration);

                    services.AddTimeRepository(hostContext.Configuration.GetConnectionString("Time"));

                    services.AddHostedService<Worker>();
                });
    }
}