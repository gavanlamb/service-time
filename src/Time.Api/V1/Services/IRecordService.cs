using System.Collections.Generic;
using Time.Api.V1.Models;

namespace Time.Api.V1.Services
{
    public interface IRecordService
    {
        IEnumerable<RecordDto> Get(
            string userId,
            int skip = 0,
            int take = 100);
    }
}