namespace Time.Api.V1.Models
{
    public class Pagination
    {
        public string PreviousPage { get; init; }
        public string NextPage { get; init; }

        public int PageNumber { get; init; }
        
        public int PageSize { get; init; }

        public int TotalPages { get; init; }
        
        public int TotalItems { get; init; }
    }
}