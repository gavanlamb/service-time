using System;
using Time.Domain.Models;

namespace Time.Domain.Commands.Records
{
    public class UpdateRecordCommand: ICommand<Record>
    {
        public long Id { get; init; }

        public string UserId { get; init; }
        
        public string Name { get; init; }
        
        public DateTime Start { get; init; }
        
        public DateTime? End { get; init; }
    }
}