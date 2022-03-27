using System;

namespace Time.Api.V1.Models;

/// <summary>
/// Create Record item
/// </summary>
public class CreateRecord
{
    /// <summary>
    /// Name of the time record
    /// </summary>
    /// <example>Meeting</example>
    public string Name { get; init; }
        
    /// <summary>
    /// Time the record started
    /// </summary>
    /// <example>2021-03-27T01:37:40.123+11:00</example>
    public DateTimeOffset Start { get; init; }
}