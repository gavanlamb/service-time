using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Moq;
using Serilog;
using Time.Domain.Behaviours;
using Time.Domain.Commands;
using Xunit;

namespace Time.Domain.UnitTests.Behaviours;

public class LoggingTests
{
    public class LoggingTestsResponse { }
    
    public class LoggingTestsRequest : ICommand<LoggingTestsResponse> { }

    [Fact]
    public async Task Success()
    {
        var logger = new Mock<ILogger>();
        var next = new Mock<RequestHandlerDelegate<LoggingTestsResponse>>();
        next.Setup(n => n()).ReturnsAsync(new LoggingTestsResponse());
        var handler = new Logging<LoggingTestsRequest, LoggingTestsResponse>(logger.Object);
        var cancellationToken = new CancellationToken();
    
        await handler.Handle(new LoggingTestsRequest(), cancellationToken, next.Object);
        
        logger.Verify(i =>  
                i.Information(
                    It.Is<string>(message => message == "Going to handle:{Name} with value:{@Request}"),
                    It.Is<string>(name => name == nameof(LoggingTestsRequest)),
                    It.IsAny<LoggingTestsRequest>()
                ), 
            Times.Once);
        
        next.Verify(n => n(), Times.Once);

        logger.Verify(i =>  
                i.Information(
                    It.Is<string>(message => message == "Handled:{Name} with value:{@Response}"),
                    It.Is<string>(name => name == nameof(LoggingTestsResponse)),
                    It.IsAny<LoggingTestsResponse>()
                ), 
            Times.Once);
    }
}