using System.Diagnostics;
using System.Reflection;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Time.Api.V1.Models;

namespace Time.Api.V1.Controllers;

[ApiController]
[ApiVersion("1.0")]
[Route("v{version:apiVersion}/[controller]")]
[Produces("application/json")]
[ProducesResponseType(typeof(GeneralException), StatusCodes.Status500InternalServerError)]
[ProducesErrorResponseType(typeof(void))]
public class ServiceController: ControllerBase
{

    private readonly ILogger<ServiceController> _logger;
    private readonly Serilog.ILogger _logger1;

    public ServiceController(
        ILogger<ServiceController> logger,
        Serilog.ILogger logger1)
    {
        _logger = logger;
        _logger1 = logger1;
    }

    /// <summary>
    /// Get service information
    /// </summary>
    /// <returns>Created record</returns>
    [HttpGet("Info")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public ActionResult<SystemInformation> Get()
    {
        var stopWatch = new Stopwatch();
        stopWatch.Start();
        for (int i = 0; i < 10000; i++)
        {
            _logger.LogInformation("This is a message about {Topic} so I can test {functionality}", "logging methods", "logging");
        }
        stopWatch.Stop();
        var ts = stopWatch.Elapsed;

        return new SystemInformation
        {
            Version = Assembly.GetEntryAssembly()?.GetName().Version.ToString(),
            Name = Assembly.GetEntryAssembly()?.GetName().Name
        };
    }

    /// <summary>
    /// Get service information
    /// </summary>
    /// <returns>Created record</returns>
    [HttpGet("Info1")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public ActionResult<SystemInformation> Get1()
    {
        var stopWatch = new Stopwatch();
        stopWatch.Start();
        for (int i = 0; i < 10000; i++)
        {
            _logger1.Information("This is a message about {Topic} so I can test {functionality}", "logging methods", "logging");
        }
        stopWatch.Stop();
        var ts = stopWatch.Elapsed;

        return new SystemInformation
        {
            Version = Assembly.GetEntryAssembly()?.GetName().Version.ToString(),
            Name = Assembly.GetEntryAssembly()?.GetName().Name
        };
    }
}