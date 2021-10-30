using MediatR;
using Time.Domain.Models;

namespace Time.Domain.Queries.Records
{
    public class GetRecordByIdQuery : IQuery, IRequest<Record>
    {
        public long Id { get; init; }
    }
}