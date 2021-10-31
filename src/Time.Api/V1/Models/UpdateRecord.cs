using System;

namespace Time.Api.V1.Models
{
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
        /// <example>2021-10-31T04:46:32.3044710Z</example>
        public DateTime Start { get; init; }
        
        /// <summary>
        /// Time the record started
        /// </summary>
        /// <example>2021-10-31T06:46:32.3044710Z</example>
        public DateTime? End { get; set; }
    }
}