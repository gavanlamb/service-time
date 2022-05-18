using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
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
        var context = new ValidationContext<TRequest>(request);

        var validationTasks = _validators
            .Select(validator => validator.ValidateAsync(context, cancellationToken))
            .ToList();
        
        var validationResults = await Task.WhenAll(validationTasks);
        
        var validationErrors = validationResults
            .SelectMany(vr => vr.Errors)
            .Where(e => e != null)
            .ToList();
        
        if (validationErrors.Any())
        {
            throw new ValidationException(validationErrors);
        }

        return await next();
    }
}