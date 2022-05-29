using System.ComponentModel;
using System.Text.Json;
using System.Text.Json.Serialization;
using Expensely.Authentication.Cognito.Jwt.Extensions;
using Expensely.Logging.Serilog.Extensions;
using Expensely.Swagger.Extensions;
using Expensely.Tracing.OpenTelemetry.Extensions;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.ApiExplorer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using Time.Api.Middleware;
using Time.Domain.Extensions;

namespace Time.Api;

public class Startup
{
    public Startup(IConfiguration configuration)
    {
        Configuration = configuration;
    }

    private IConfiguration Configuration { get; }

    // This method gets called by the runtime. Use this method to add services to the container.
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllers()
            .AddJsonOptions(options =>
            {
                options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
                options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
                options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
            });

        Tracing.AddOpenTelemetry(Configuration);
        
        services.AddSerilog(Configuration);

        services.AddSwagger();
        
        services.AddHealthChecks();
        
        services.AddCognitoJwt(Configuration);
        
        services.AddAutoMapper(typeof(Startup));
        
        services.AddTimeDomain(Configuration);
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env, IApiVersionDescriptionProvider provider)
    {
        if (env.IsDevelopment() || env.EnvironmentName.StartsWith("Preview"))
        {
            app.UseDeveloperExceptionPage();
        }

        app.UseSwagger(provider);
            
        app.UseSerilogRequestLogging();

        app.UseMiddleware(typeof(ErrorHandling));
            
        app.UseRouting();

        app.UseAuth();

        app.UseEndpoints(endpoints =>
        {
            endpoints.MapHealthChecks("/health");
            endpoints.MapControllers();
        });
    }
}