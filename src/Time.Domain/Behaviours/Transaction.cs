using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Time.Database;
using Time.Domain.Commands;

namespace Time.Domain.Behaviours;

public class Transaction<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse> where TRequest : ICommand<TResponse>
{
    private readonly TimeContext _timeContext;

    public Transaction(
        TimeContext timeContext)
    {
        _timeContext = timeContext;
    }

    public async Task<TResponse> Handle(
        TRequest request, 
        CancellationToken cancellationToken,
        RequestHandlerDelegate<TResponse> next)
    {
        await using var transaction = await _timeContext.Database.BeginTransactionAsync(cancellationToken);

        var response = await next();
            
        await transaction.CommitAsync(cancellationToken);

        return response;
    }
}