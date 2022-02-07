using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Amazon.XRay.Recorder.Core;
using FluentValidation;
using MediatR;
using Time.Domain.Commands;

namespace Time.Domain.Behaviours;

public class Validation<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse> where TRequest : ICommand<TResponse>
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;
        
    public Validation(IEnumerable<IValidator<TRequest>> validators)
    {
        _validators = validators;
    }

    public async Task<TResponse> Handle(
        TRequest request, 
        CancellationToken cancellationToken, 
        RequestHandlerDelegate<TResponse> next)
    {
        AWSXRayRecorder.Instance.BeginSubsegment("Validation");
        var context = new ValidationContext<TRequest>(request);

        var validationErrors = _validators
            .Select(x => x.Validate(context))
            .SelectMany(x => x.Errors)
            .Where(x => x != null)
            .ToList();

        if (validationErrors.Any())
        {
            throw new ValidationException(validationErrors);
        }
        AWSXRayRecorder.Instance.EndSubsegment();

        return await next();
    }
}