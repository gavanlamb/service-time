using MediatR;

namespace Time.Domain.Commands.Records
{
    public class DeleteRecordCommand : ICommand, IRequest<bool>
    {
        public long Id { get; init; }
    }
}