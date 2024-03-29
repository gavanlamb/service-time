using System;
using Time.Domain.Models;

namespace Time.Domain.Commands.Records;

public class CreateRecordCommand : ICommand<Record>
{
    public string Name { get; init; }
    public string UserId { get; init; }
    public DateTimeOffset Start { get; init; }
}