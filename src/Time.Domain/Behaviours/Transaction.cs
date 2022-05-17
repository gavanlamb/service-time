using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Time.Database;
using Time.Domain.Commands;

namespace Time.Domain.Behaviours;

public class Transaction<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse> where TRequest : ICommand<TResponse>
{
    private readonly TimeCommandContext _timeContext;

    public Transaction(
        TimeCommandContext timeContext)
    {
        _timeContext = timeContext;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        CancellationToken cancellationToken,
        RequestHandlerDelegate<TResponse> next)
    {
        await using var transaction = await _timeContext.Database.BeginTransactionAsync(cancellationToken);
        
        try
        {
            var response = await next();
            
            await transaction.CommitAsync(cancellationToken);

            return response;
        }
        catch (Exception _)
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }
}