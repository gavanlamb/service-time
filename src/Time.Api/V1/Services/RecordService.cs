using System.Collections.Generic;
using System.Linq;
using Time.Api.V1.Mappers;
using Time.Api.V1.Models;
using Time.DbContext.Repositories;

namespace Time.Api.V1.Services
{
    public class RecordService : IRecordService
    {
        private readonly IRecordRepository _recordRepository;

        public RecordService(
            IRecordRepository recordRepository)
        {
            _recordRepository = recordRepository;
        }

        public IEnumerable<RecordDto> Get(
            string userId, 
            int skip = 0, 
            int take = 100)
        {
            var records = _recordRepository.Get(userId, skip, take);

            return records.Any() ? records.Select(record => record.MapDto()) : new List<RecordDto>();
        }
    }
}