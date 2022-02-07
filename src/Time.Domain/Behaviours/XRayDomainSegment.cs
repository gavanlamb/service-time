using System.Threading;
using System.Threading.Tasks;
using Amazon.XRay.Recorder.Core;
using MediatR;

namespace Time.Domain.Behaviours;

public class XRaySegment<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse> where TRequest : IRequest<TResponse>
{
    public Task<TResponse> Handle(
        TRequest request, 
        CancellationToken cancellationToken, 
        RequestHandlerDelegate<TResponse> next)
    {
        AWSXRayRecorder.Instance.BeginSubsegment("Request");
        
        var response = next();
        
        AWSXRayRecorder.Instance.EndSubsegment();

        return response;
    }
}