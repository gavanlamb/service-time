namespace Time.Domain.Commands.Records;

public class DeleteRecordCommand : ICommand<bool>
{
    public long Id { get; init; }
        
    public string UserId { get; init; }
}