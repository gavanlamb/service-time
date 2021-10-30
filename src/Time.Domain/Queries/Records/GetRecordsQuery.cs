using MediatR;
using Time.Domain.Models;

namespace Time.Domain.Queries.Records
{
    public class GetRecordsQuery : IQuery, IRequest<Paged<Record>>
    {
        public int PageNumber { get; init; }

        public int PageSize { get; init; }

        public string UserId { get; set; }
    }
}