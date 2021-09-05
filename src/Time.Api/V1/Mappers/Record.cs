using Time.Api.V1.Models;
using Time.DbContext.Entities;

namespace Time.Api.V1.Mappers
{
    public static class Record
    {
        public static RecordDto MapDto(this RecordEntity record)
        {
            return new()
            {
                Id = record.Id,
                Name = record.Name,
                End = record.End,
                Start = record.Start,
                Duration = record.Duration.ToString()
            };
        }
    }
}