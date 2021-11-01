using System;

namespace Time.Api.V1.Models
{
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
        /// <example></example>
        public string Name { get; set; }
        
        /// <summary>
        /// The start date and time, in UTC, for this record.
        /// </summary>
        /// <example>2021-10-31T04:46:32.3044710Z</example>
        public DateTime Start { get; set; }
        
        /// <summary>
        /// The end date and time, in UTC for, this record. This value might be null if the record is still active.
        /// </summary>
        /// <example>2021-10-31T06:46:32.3044710Z</example>
        public DateTime? End { get; set; }

        /// <summary>
        /// The duration for this record. This might be null if the end time is not set.
        /// </summary>
        /// <example></example>
        public TimeSpan Duration { get; set; }
    }
}