using System;
using System.Linq;
using System.Net;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using FluentValidation;
using Microsoft.AspNetCore.Http;
using Serilog;
using Time.Api.V1.Models;

namespace Time.Api.Middleware;

public class ErrorHandling
{
    private readonly RequestDelegate _next;
    private readonly ILogger _logger;
        
    public ErrorHandling(
        RequestDelegate next, 
        ILogger logger)
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
            _logger.Error(exception, $"{nameof(ValidationException)} occurred while executing the request");
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
                    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
                    Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                });
            await context.Response.WriteAsync(serialisedResponse);
        }
        catch (Exception exception)
        {
            _logger.Error(exception, $"{nameof(Exception)} occurred while executing the request");
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            var response = new GeneralException
            {
                Message = $"${nameof(Exception)} occurred while executing the request"
            };
            var serialisedResponse = JsonSerializer.Serialize(
                response,
                new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
                    Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                });
            await context.Response.WriteAsync(serialisedResponse);
        }
    }
}