using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Expensely.Authentication.Cognito.Jwt.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Time.Api.V1.Models;
using Time.Api.V1.Services;

namespace Time.Api.V1.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/[controller]")]
    [Produces("application/json")]
    public class RecordController : ControllerBase
    {
        private readonly IRecordService _recordService;
        private readonly ILogger<RecordController> _logger;

        public RecordController(
            ILogger<RecordController> logger,
            IRecordService recordService)
        {
            _logger = logger;
            _recordService = recordService;
        }

        /// <summary>
        /// Get the time records for the authorised user. This endpoint implements pagination
        /// </summary>
        /// <returns>A list of records or an empty list.</returns>
        /// <response code="200">Retrieved paginated records for user</response>
        /// <response code="204">Retrieved paginated records for user</response>
        /// <response code="401">User is unauthorised</response>
        /// <response code="403">User is forbidden</response>
        /// <response code="500">Oops! An error occurred.</response>
        [HttpGet]
        [Authorize("read")]
        public async Task<ActionResult<IEnumerable<RecordDto>>> Get()
        {
            try
            {
                var userId = User.GetSubject();
                var records = _recordService.Get(userId);
                if (records.Any())
                {
                    return Ok(records);
                }

                return NoContent();

            }
            catch (Exception e)
            {
                _logger.LogError(
                    e, 
                    "Error encountered while getting records for user"); 

                return StatusCode(500);
            }
        }
    }
}