using System.Collections.Generic;
using Time.Api.Models;

namespace Time.Api.Services
{
    public interface IRecordService
    {
        IEnumerable<RecordDto> Get(
            string userId,
            int skip = 0,
            int take = 100);
    }
}