using System.Collections.Generic;
using System.Linq;
using Time.DbContext.Entities;

namespace Time.DbContext.Repositories
{
    public class RecordRepository : IRecordRepository
    {
        private readonly TimeDbContext _context;
        public RecordRepository(
            TimeDbContext context)
        {
            _context = context;
        }

        public IEnumerable<RecordEntity> Get(
            string userId,
            int skip,
            int take)
        {
            return _context.Records
                .Where(record => record.UserId == userId)
                .OrderByDescending(record => record.Start)
                .Skip(skip)
                .Take(take)
                .ToList();
        }
    }
}