using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Threading.Tasks;
using FluentValidation;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Time.Api.V1.Models;

namespace Time.Api.Middleware
{
    public class ErrorHandling
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ErrorHandling> _logger;
        
        public ErrorHandling(
            RequestDelegate next, 
            ILogger<ErrorHandling> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task Invoke(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (ValidationException exception)
            {
                _logger.LogError(exception, "ValidationException occured while executing the request");
                context.Response.ContentType = "application/json";
                context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                var response = exception.Errors
                    .GroupBy(e => e.PropertyName)
                    .ToDictionary(g => g.Key, g=> g.Select(i => i.ErrorMessage));
                var serialisedResponse = JsonSerializer.Serialize(
                    response,
                    new JsonSerializerOptions
                    {
                        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                        IgnoreNullValues = true,
                        Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                    });
                await context.Response.WriteAsync(serialisedResponse);
            }
            catch (Exception exception)
            {
                _logger.LogError(exception, "Exception occured while executing the request");
                context.Response.ContentType = "application/json";
                context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
                var response = new GeneralException
                {
                    Message = "Exception occured while executing the request"
                };
                var serialisedResponse = JsonSerializer.Serialize(
                    response,
                    new JsonSerializerOptions
                    {
                        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                        IgnoreNullValues = true,
                        Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                    });
                await context.Response.WriteAsync(serialisedResponse);
            }
        }
    }
}