using System.Threading;
using System.Threading.Tasks;
using MediatR;

namespace Time.Domain.Behaviours;

public class XRaySegment<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse> where TRequest : IRequest<TResponse>
{
    public async Task<TResponse> Handle(
        TRequest request, 
        CancellationToken cancellationToken, 
        RequestHandlerDelegate<TResponse> next)
    {
        var response = await next();

        return response;
    }
}