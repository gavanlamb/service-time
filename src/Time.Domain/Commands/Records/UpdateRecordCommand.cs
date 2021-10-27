using System;
using MediatR;
using Time.Domain.Models;

namespace Time.Domain.Commands.Records
{
    public class UpdateRecordCommand: ICommand, IRequest<Record>
    {
        public long Id { get; set; }

        public string Name { get; set; }
        
        public DateTime Start { get; set; }
        
        public DateTime? End { get; set; }
    }
}