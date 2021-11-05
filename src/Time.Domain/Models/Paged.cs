using System.Collections.Generic;

namespace Time.Domain.Models
{
    public class Paged<T>
    {
        public int TotalPages { get; init; }
        public int TotalItems { get; init; }
        public int PageSize { get; init; }
        public int PageNumber { get; init; }
        public IEnumerable<T> Items { get; init; }
    }
}