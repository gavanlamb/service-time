using Time.Domain.Models;

namespace Time.Domain.Queries.Records;

public class GetRecordsQuery : IQuery<Paged<Record>>
{
    public int PageNumber { get; init; }

    public int PageSize { get; init; }

    public string UserId { get; set; }

    public RecordType? Type { get; set; }
}

public enum RecordType
{
    All,
    Open,
    Closed
}