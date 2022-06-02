using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage;
using Moq;
using Time.Database;
using Time.Domain.Behaviours;
using Time.Domain.Commands;
using Xunit;

namespace Time.Domain.UnitTests.Behaviours;

public class TransactionTests
{
    [Fact]
    public async Task Success()
    {
        var (db, handler, transaction) = Setup();
        var next = new Mock<RequestHandlerDelegate<TransactionTestsResponse>>();
        next.Setup(n => n()).ReturnsAsync(new TransactionTestsResponse());
        var cancellationToken = new CancellationToken();
    
        await handler.Handle(
            new TransactionTestsRequest(),
            cancellationToken,
            next.Object);
    
        db.Verify(d => d.BeginTransactionAsync(cancellationToken), Times.Once);
        next.Verify(n => n(), Times.Once);
        transaction.Verify(t => t.CommitAsync(cancellationToken), Times.Once);
    }
    
    [Fact]
    public async Task Failure()
    {
        var (db, handler,  transaction) = Setup();
        var next = new Mock<RequestHandlerDelegate<TransactionTestsResponse>>();
        next.Setup(n => n()).Throws(new Exception());
        var cancellationToken = new CancellationToken();
    
        Func<Task> act = async () => await handler.Handle(
            new TransactionTestsRequest(),
            cancellationToken,
            next.Object);
        
        await Assert.ThrowsAsync<Exception>(act);
        db.Verify(d => d.BeginTransactionAsync(cancellationToken), Times.Once);
        next.Verify(n => n(), Times.Once);
        transaction.Verify(t => t.RollbackAsync(cancellationToken), Times.Once);
    }
    
    private static (
        Mock<DatabaseFacade> db,
        Transaction<TransactionTestsRequest, TransactionTestsResponse> handler,
        Mock<IDbContextTransaction> transaction) Setup()
    {
        var context = new Mock<TimeCommandContext>(new DbContextOptions<TimeCommandContext>());
        var db = new Mock<DatabaseFacade>(context.Object);
        var transaction = new Mock<IDbContextTransaction>();
        context.Setup(c => c.Database).Returns(db.Object);
        db.Setup(d => d.BeginTransactionAsync(It.IsAny<CancellationToken>())).ReturnsAsync(transaction.Object);

        var handler = new Transaction<TransactionTestsRequest, TransactionTestsResponse>(context.Object);
    
        return (db, handler, transaction);
    }
    
    public class TransactionTestsResponse { }
    
    public class TransactionTestsRequest : ICommand<TransactionTestsResponse> { }
}