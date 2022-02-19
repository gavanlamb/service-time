using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Serilog;
using Time.Domain.Commands;

namespace Time.Domain.Behaviours;

public class Logging<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse> where TRequest : ICommand<TResponse>
{
    private readonly ILogger _logger;
        
    public Logging(
        ILogger logger)
    {
        _logger = logger;
    }
        
    public async Task<TResponse> Handle(
        TRequest request, 
        CancellationToken cancellationToken, 
        RequestHandlerDelegate<TResponse> next)
    {
        _logger.Information(
            "Going to handle:{Name} with value:{@Request}", 
            typeof(TRequest).Name,
            request);
            
        var response = await next();
            
        _logger.Information(
            "Handled:{Name} with value:{@Response}", 
            typeof(TRequest).Name,
            response);

        return response;
    }
}