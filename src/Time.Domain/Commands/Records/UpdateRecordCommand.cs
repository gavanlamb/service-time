using System;
using Time.Domain.Models;

namespace Time.Domain.Commands.Records
{
    public class UpdateRecordCommand: ICommand<Record>
    {
        public long Id { get; init; }

        public string UserId { get; init; }
        
        public string Name { get; init; }
        
        public DateTimeOffset Start { get; init; }
        
        public DateTimeOffset? End { get; init; }
    }
}