using System.Collections.Generic;
using System.Linq;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Threading.Tasks;
using AutoMapper;
using Expensely.Authentication.Cognito.Jwt.Extensions;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Time.Api.V1.Models;
using Time.Domain.Commands.Records;
using Time.Domain.Queries.Records;

namespace Time.Api.V1.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("v{version:apiVersion}/[controller]")]
    [Produces("application/json")]
    public class RecordController : ControllerBase
    {
        private readonly ILogger<RecordController> _logger;
        private readonly IMapper _mapper;
        private readonly IMediator _mediatr;

        public RecordController(
            ILogger<RecordController> logger,
            IMapper mapper,
            IMediator mediatr)
        {
            _logger = logger;
            _mapper = mapper;
            _mediatr = mediatr;
        }

        /// <summary>
        /// Create a record
        /// </summary>
        /// <param name="createRecord">Record details</param>
        /// <returns>Created record</returns>
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
            var userId = HttpContext.User.GetSubject();
            
            var command = _mapper.Map<CreateRecordCommand>(createRecord, opt => opt.Items["UserId"] = userId);
            
            var recordDomain = await _mediatr.Send(command);
            
            var record = _mapper.Map<Record>(recordDomain);
            
            return CreatedAtAction(nameof(Get), new { id = record.Id }, record);
        }

        /// <summary>
        /// Update a record
        /// </summary>
        /// <param name="id">Identifier of the record to update</param>
        /// <param name="updateRecord">Record details</param>
        /// <returns>Update record</returns>
        [HttpPut("{id:long}")]
        [Authorize("update")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        [ProducesErrorResponseType(typeof(void))]
        public async Task<ActionResult<Record>> Put(
            [FromRoute] long id,
            [FromBody] UpdateRecord updateRecord)
        {
            var userId = HttpContext.User.GetSubject();
            
            var command = _mapper.Map<UpdateRecordCommand>(
                updateRecord, 
                opt =>
                {
                    opt.Items["UserId"] = userId;
                    opt.Items["Id"] = id;
                });
            
            var recordDomain = await _mediatr.Send(command);
            
            var record = _mapper.Map<Record>(recordDomain);

            return Ok(record);
        }
        
        /// <summary>
        /// Delete a record
        /// </summary>
        /// <param name="id">Identifier of the record to delete</param>
        [HttpDelete("{id:long}")]
        [Authorize("delete")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        [ProducesErrorResponseType(typeof(void))]
        public async Task<ActionResult> Delete(
            [FromRoute] long id)
        {
            var userId = HttpContext.User.GetSubject();
            
            var command = _mapper.Map<DeleteRecordCommand>(id, opt => opt.Items["UserId"] = userId);

            await _mediatr.Send(command);
            
            return Ok();
        }
        
        /// <summary>
        /// Get a record
        /// </summary>
        /// <param name="id">Identifier of the record to get</param>
        /// <returns>Found record</returns>
        [HttpGet("{id:long}")]
        [Authorize("read")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        [ProducesErrorResponseType(typeof(void))]
        public async Task<ActionResult<Record>> Get(
            [FromRoute] long id)
        {
            var userId = HttpContext.User.GetSubject();
            
            var query = _mapper.Map<GetRecordByIdQuery>(id, opt => opt.Items["UserId"] = userId);
            
            var result = await _mediatr.Send(query);
            if (result == null)
            {
                return NotFound();
            }
            
            var record = _mapper.Map<Record>(result);
            
            return Ok(record);
        }
        
        /// <summary>
        /// Get records
        /// </summary>
        /// <param name="pageNumber">Page number to retrieve</param>
        /// <param name="PageSize">Amount of items to retrieve</param>
        /// <returns>A collection of records</returns>
        [HttpGet]
        [Authorize("read")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        [ProducesErrorResponseType(typeof(void))]
        public async Task<ActionResult<IEnumerable<Record>>> Fetch(
            [FromQuery] int pageNumber,
            [FromQuery] int PageSize)
        {
            var userId = HttpContext.User.GetSubject();
            
            var query = new GetRecordsQuery
            {
                PageNumber = pageNumber,
                PageSize = PageSize,
                UserId = userId
            };
            
            var result = await _mediatr.Send(query);
            if (!result.Items.Any())
                return NoContent();

            var records = _mapper.Map<IEnumerable<Record>>(result.Items);

            var paginationDetails = Helpers.Pagination.GetPaginationDetails(
                Url,
                result,
                nameof(Fetch));
            
            Response.Headers.Add(
                "X-Pagination", 
                JsonSerializer.Serialize(
                    paginationDetails,
                    new JsonSerializerOptions
                    {
                        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                        IgnoreNullValues = true,
                        Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                    })
                );

            return Ok(records);
        }
    }
}
