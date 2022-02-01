namespace Time.Api.V1.Models;

/// <summary>
/// Object for the X-Pagination record header
/// </summary>
public class Pagination
{
    /// <summary>
    /// Link to previous pagination record
    /// </summary>
    public string PreviousPage { get; init; }
        
    /// <summary>
    /// Link to next pagination record
    /// </summary>
    public string NextPage { get; init; }

    /// <summary>
    /// Current page number
    /// </summary>
    public int PageNumber { get; init; }

    /// <summary>
    /// Current page size
    /// </summary>
    public int PageSize { get; init; }
        
    /// <summary>
    /// Total pages available
    /// </summary>
    public int TotalPages { get; init; }
        
    /// <summary>
    /// Total items available
    /// </summary>
    public int TotalItems { get; init; }
}