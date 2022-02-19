using System;
using System.Diagnostics;
using System.Reflection;
using System.Text.Json;
using Expensely.Authentication.Cognito.Jwt.Extensions;
using Expensely.Logging.Serilog.Enrichers;
using Expensely.Logging.Serilog.Extensions;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ApiExplorer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Npgsql;
using OpenTelemetry;
using OpenTelemetry.Contrib.Extensions.AWSXRay.Trace;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Serilog;
using Serilog.Configuration;
using Serilog.Enrichers.Span;
using Serilog.Exceptions;
using Serilog.Formatting.Json;
using Swashbuckle.AspNetCore.SwaggerGen;
using Time.Api.Middleware;
using Time.Api.Setup;
using Time.Domain.Behaviours;
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

        // TODO create package with opentracing
        Activity.DefaultIdFormat = ActivityIdFormat.Hierarchical;
        Sdk.CreateTracerProviderBuilder()
            .SetResourceBuilder(ResourceBuilder
                .CreateDefault()
                .AddService(
                    Assembly.GetEntryAssembly()?.GetName().Name,
                    "Expensely",
                    Assembly.GetEntryAssembly()?.GetName().Version.ToString())
                .AddTelemetrySdk())
            .AddXRayTraceId()
            .AddAWSInstrumentation()
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddNpgsql()
            .SetErrorStatusOnException()
            .AddOtlpExporter(options => 
            {
                options.Endpoint = new Uri(Configuration.GetValue<string>("OpenTelemetry:Endpoint"));
            })
            .Build();
        Sdk.SetDefaultTextMapPropagator(new AWSXRayPropagator());

        Logging.AddSerilog(Configuration);
        services.AddSingleton(Log.Logger);

        services.AddMvcCore()
            .AddApiExplorer();

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
            // TODO health check requests don't include trace id - please fix
            endpoints.MapHealthChecks("/health");
            endpoints.MapControllers();
        });
    }
}