using Time.Domain.Models;

namespace Time.Domain.Queries.Records;

public class GetRecordByIdQuery : IQuery<Record>
{
    public long Id { get; init; }

    public string UserId { get; init; }
}