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
        using var transaction = _timeContext.Database.BeginTransaction();

        var response = await next();
            
        transaction.Commit();

        return response;
    }
}