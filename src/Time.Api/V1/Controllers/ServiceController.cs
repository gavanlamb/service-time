using System.Reflection;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
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
    /// <summary>
    /// Get service information
    /// </summary>
    /// <returns>Created record</returns>
    [HttpGet("Info")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public ActionResult<SystemInformation> Get()
    {
        return new SystemInformation
        {
            Version = Assembly.GetEntryAssembly()?.GetName().Version.ToString(),
            Name = Assembly.GetEntryAssembly()?.GetName().Name
        };
    }
}