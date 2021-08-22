using System.Collections.Generic;
using System.Linq;
using Time.Api.Models;
using Time.DbContext.Repositories;

namespace Time.Api.Services
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

            if (records.Any())
            {
                
            }

            return new List<RecordDto>();
        }
    }
}