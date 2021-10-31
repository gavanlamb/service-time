using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Time.Api.V1.Models;
using Time.Domain.Commands.Records;

namespace Time.Api.V1.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("v{version:apiVersion}/[controller]")]
    [Produces("application/json")]
    public class RecordController : ControllerBase
    {
        private readonly ILogger<RecordController> _logger;
        private readonly IMediator _mediatr;

        public RecordController(
            ILogger<RecordController> logger,
            IMediator mediatr)
        {
            _logger = logger;
            _mediatr = mediatr;
        }

        // Post
        [HttpPost]
        // TODO attributes
        public async Task<ActionResult<Record>> Post(
            [FromBody] CreateRecord createRecord)
        {
            var command = new CreateRecordCommand
            {
                Name = createRecord.Name,
                Start = createRecord.Start,
                UserId = "user id"
            };
            var record = await _mediatr.Send(command);
            return Ok(record);
        }

        // Put
        [HttpPut("{id:long}")]
        // TODO attributes
        public async Task<ActionResult<Record>> Put(
            [FromRoute] long id,
            [FromBody] UpdateRecord updateRecord)
        {
            var command = new UpdateRecordCommand
            {
                Id = id,
                Name = updateRecord.Name,
                Start = updateRecord.Start,
                End = updateRecord.End,
                UserId = "user id"
            };
            var record = await _mediatr.Send(command);
            return Ok(record);
        }

        // Put
        
        // Delete
        
        // Get by Id
        
        // Fetch - paged


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
        public async Task<ActionResult<IEnumerable<Record>>> Get()
        {
            try
            {
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