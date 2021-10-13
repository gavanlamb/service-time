using System.Collections.Generic;
using Time.Database.Entities;

namespace Time.Database.Repositories
{
    public interface IRecordRepository
    {
        IEnumerable<Record> Get(
            string userId,
            int skip,
            int take);
    }
}