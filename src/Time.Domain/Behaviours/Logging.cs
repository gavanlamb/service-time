using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using Time.Domain.Commands;

namespace Time.Domain.Behaviours
{
    public class Logging<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse> where TRequest : ICommand<TResponse>
    {
        private readonly ILogger<Logging<TRequest, TResponse>> _logger;
        
        public Logging(
            ILogger<Logging<TRequest, TResponse>> logger)
        {
            _logger = logger;
        }
        
        public async Task<TResponse> Handle(
            TRequest request, 
            CancellationToken cancellationToken, 
            RequestHandlerDelegate<TResponse> next)
        {
            _logger.LogInformation(
                "Going to handle:{Name} with value:{@Request}", 
                typeof(TRequest).Name,
                request);
            
            var response = await next();
            
            _logger.LogInformation(
                "Handled:{Name} with value:{@Response}", 
                typeof(TRequest).Name,
                response);

            return response;
        }
    }
}