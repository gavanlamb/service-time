using System;

namespace Time.Api.V1.Models
{
    /// <summary>
    /// Update Record item
    /// </summary>
    public class UpdateRecord
    {
        /// <summary>
        /// Name of the time record
        /// </summary>
        /// <example>Meeting</example>
        public string Name { get; init; }
        
        /// <summary>
        /// Time the record started
        /// </summary>
        public DateTimeOffset Start { get; init; }
        
        /// <summary>
        /// Time the record started
        /// </summary>
        public DateTimeOffset? End { get; set; }
    }
}