using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
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

        [HttpPost]
        [Authorize("create")]
        [ProducesResponseType(StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        [ProducesErrorResponseType(typeof(void))]
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
            
            return CreatedAtAction(nameof(Get), new { id = record.Id }, record);
        }

        [HttpPut("{id:long}")]
        [Authorize("update")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
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
        
        [HttpDelete("{id:long}")]
        [Authorize("delete")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<ActionResult<Record>> Delete(
            [FromRoute] long id)
        {
            var command = new DeleteRecordCommand
            {
                Id = id,
                UserId = "user id"
            };
            await _mediatr.Send(command);
            return Ok();
        }
        
        [HttpGet("{id:long}")]
        [Authorize("read")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<ActionResult<Record>> Get(
            [FromRoute] long id)
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
        
        [HttpGet]
        [Authorize("read")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<ActionResult<IEnumerable<Record>>> Fetch()
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