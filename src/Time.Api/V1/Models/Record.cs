using System;

namespace Time.Api.V1.Models;

/// <summary>
/// Record item
/// </summary>
public class Record
{
    /// <summary>
    /// Identifier for the time record. This is globally unique.
    /// </summary>
    /// <example>213</example>
    public long Id { get; set; }
        
    /// <summary>
    /// Name of the time record.
    /// </summary>
    /// <example>Meeting</example>
    public string Name { get; set; }
        
    /// <summary>
    /// The start date and time, in UTC, for this record.
    /// </summary>
    /// <example>2021-03-27T01:37:40.123+00:00</example>
    public DateTimeOffset Start { get; set; }
        
    /// <summary>
    /// The end date and time, in UTC for, this record. This value might be null if the record is still active.
    /// </summary>
    /// <example>2021-03-27T02:37:40.123+00:00</example>
    public DateTimeOffset? End { get; set; }

    /// <summary>
    /// The duration in seconds for this record. This will be null if the end time is not set.
    /// </summary>
    public double? Duration { get; set; }
}