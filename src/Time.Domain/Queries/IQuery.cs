using MediatR;

namespace Time.Domain.Queries
{
    public interface IQuery<out TResponse> : IRequest<TResponse>
    {
    }
}