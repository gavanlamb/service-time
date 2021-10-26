using System;
using MediatR;
using Time.Domain.Models;

namespace Time.Domain.Commands.Records
{
    public class CreateRecordCommand : ICommand, IRequest<Record>
    {
        public string Name { get; init; }
        public string UserId { get; init; }
        public DateTime Start { get; init; }
    }
}