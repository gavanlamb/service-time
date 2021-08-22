using System.Collections.Generic;
using Expensely.Authentication.Cognito.Jwt.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Time.Api.Models;
using Time.Api.Services;

namespace Time.Api.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Produces("application/json")]
    public class RecordController : ControllerBase
    {
        private readonly IRecordService _recordService;

        public RecordController(
            IRecordService recordService)
        {
            _recordService = recordService;
        }

        /// <summary>
        /// Get the time records for the authorised user. This endpoint implements pagination
        /// </summary>
        /// <returns>A list of records or an empty list.</returns>
        /// <response code="200">Retrieved paginated records for user</response>
        /// <response code="401">User is unauthorised</response>
        /// <response code="403">User is forbidden</response>
        /// <response code="500">Oops! An error occurred.</response>
        [HttpGet]
        [Authorize("read")]
        public IEnumerable<RecordDto> Get()
        {
            var userId = User.GetSubject();
            return _recordService.Get(userId);
        }
    }
}