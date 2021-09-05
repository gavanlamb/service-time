using System.Collections.Generic;
using System.Text.Json;
using Expensely.Authentication.Cognito.Jwt.Extensions;
using Expensely.Logging.Serilog;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ApiExplorer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using Microsoft.OpenApi.Models;
using Serilog;
using Swashbuckle.AspNetCore.SwaggerGen;
using Time.Api.Setup;
using Time.Api.V1.Services;
using Time.DbContext.Extensions;

namespace Time.Api
{
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
            services
                .AddControllers()
                .AddJsonOptions(options =>
                {
                    options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
                    options.JsonSerializerOptions.IgnoreNullValues = true;
                });

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

            services.AddTimeRepository(Configuration);

            Logging.AddSerilog(Configuration);

            services.AddHealthChecks();

            services.AddCognitoJwt(Configuration);

            services.AddScoped<IRecordService, RecordService>();
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, IApiVersionDescriptionProvider provider)
        {
            if (env.IsDevelopment() ||  env.EnvironmentName.StartsWith("Preview"))
            {
                app.UseDeveloperExceptionPage();
                
                app.UseSwagger(options =>
                {
                    options.PreSerializeFilters.Add((swagger, req) =>
                    {
                        swagger.Servers = new List<OpenApiServer>
                        {
                            new()
                            {
                                Url = $"https://{req.Host}"
                            },
                            new()
                            {
                                Url = $"http://{req.Host}"
                            }
                        };
                    });
                });

                app.UseSwaggerUI(options =>
                {
                    foreach (var desc in provider.ApiVersionDescriptions)
                    {
                        options.SwaggerEndpoint($"/swagger/{desc.GroupName}/swagger.json", $"Version {desc.ApiVersion}");
                        options.DefaultModelsExpandDepth(-1);
                    }
                });
            }

            app.UseSerilogRequestLogging();

            app.UseRouting();

            app.UseAuth();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapHealthChecks("/health");
            });

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}