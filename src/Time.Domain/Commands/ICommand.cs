using MediatR;

namespace Time.Domain.Commands
{
    public interface ICommand<out TResponse> : IRequest<TResponse>
    {
    }
}