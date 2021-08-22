using System.Collections.Generic;
using Time.DbContext.Entities;

namespace Time.DbContext.Repositories
{
    public interface IRecordRepository
    {
        IEnumerable<RecordEntity> Get(
            string userId,
            int skip,
            int take);
    }
}