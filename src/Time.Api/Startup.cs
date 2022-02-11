using System;
using System.Text.Json;
using Expensely.Authentication.Cognito.Jwt.Extensions;
using Expensely.Logging.Serilog.Extensions;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ApiExplorer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Serilog;
using Swashbuckle.AspNetCore.SwaggerGen;
using Time.Api.Middleware;
using Time.Api.Setup;
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
                options.JsonSerializerOptions.IgnoreNullValues = true;
            });

        services.AddMvcCore()
            .AddApiExplorer();

        services.AddOpenTelemetryTracing(builder => builder
            .AddAspNetCoreInstrumentation()
            .SetResourceBuilder(ResourceBuilder.CreateDefault()
                .AddTelemetrySdk()
                .AddEnvironmentVariableDetector())
            .AddXRayTraceId()
            .AddAWSInstrumentation()
            .AddHttpClientInstrumentation()
            .AddEntityFrameworkCoreInstrumentation()
            .AddOtlpExporter(options => 
            {
                options.Endpoint = new Uri(Configuration.GetValue<string>("OpenTelemetry__Endpoint"));
            })
            .Build());

        services.AddApiVersioning(options =>
        {
            options.ReportApiVersions = true;
            options.DefaultApiVersion = new ApiVersion(1, 0);
        });
        services.AddVersionedApiExplorer(options =>
        {
            options.GroupNameFormat = "'v'VVV";
            options.SubstituteApiVersionInUrl = true;
        });
        services.AddTransient<IConfigureOptions<SwaggerGenOptions>, SwaggerConfigureOptions>();
        services.AddSwaggerGen(options => options.OperationFilter<SwaggerDefaultValues>());
            
        services.AddHealthChecks();
            
        services.AddCognitoJwt(Configuration);
            
        services.AddHttpContextAccessor();
        Logging.AddSerilog(Configuration);
            
        services.AddAutoMapper(typeof(Startup));
            
        services.AddTimeDomain(Configuration);
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env, IApiVersionDescriptionProvider provider)
    {
        if (env.IsDevelopment() || env.EnvironmentName.StartsWith("Preview"))
        {
            app.UseDeveloperExceptionPage();
        }

        app.UseSwagger();

        app.UseSwaggerUI(options =>
        {
            foreach (var desc in provider.ApiVersionDescriptions)
            {
                options.SwaggerEndpoint($"/swagger/{desc.GroupName}/swagger.json", $"Version {desc.ApiVersion}");
                options.DefaultModelsExpandDepth(-1);
            }
        });
            
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