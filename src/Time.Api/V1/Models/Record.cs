using System;

namespace Time.Api.V1.Models
{
    public class Record
    {
        /// <summary>
        /// Identifier for the time record. This is globally unique.
        /// </summary>
        /// <example></example>
        public Guid Id { get; set; }
        
        /// <summary>
        /// Name of the time record.
        /// </summary>
        /// <example></example>
        public string Name { get; set; }
        
        /// <summary>
        /// The start date and time, in UTC, for this record.
        /// </summary>
        /// <example></example>
        public DateTime Start { get; set; }
        
        /// <summary>
        /// The end date and time, in UTC for, this record. This value might be null if the record is still active.
        /// </summary>
        /// <example></example>
        public DateTime? End { get; set; }

        /// <summary>
        /// The duration for this record. This might be null if the end date and time is not set.
        /// </summary>
        /// <example></example>
        public string Duration { get; set; }
    }
}