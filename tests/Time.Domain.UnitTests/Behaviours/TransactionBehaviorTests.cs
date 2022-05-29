namespace Time.Domain.UnitTests.Behaviours;

public class TransactionBehaviorTests
{
    // [Fact]
    //     public async Task Handle_StartTransaction()
    //     {
    //         (Mock<DatabaseFacade> db,
    //                 TransactionBehavior<TransactionBehaviorTestsRequest, TransactionBehaviorTestsResponse> handler, _) =
    //             Setup();
    //         var cancellationToken = new CancellationToken();
    //
    //         await handler.Handle(new TransactionBehaviorTestsRequest(), cancellationToken,
    //             () => Task.Run(() => new TransactionBehaviorTestsResponse(), cancellationToken));
    //
    //         db.Verify(d => d.BeginTransactionAsync(cancellationToken), Times.Once);
    //     }
    //
    //     [Fact]
    //     public async Task Handle_EndTransaction()
    //     {
    //         (_, TransactionBehavior<TransactionBehaviorTestsRequest, TransactionBehaviorTestsResponse> handler,
    //                 Mock<IDbContextTransaction> transaction) =
    //             Setup();
    //         var cancellationToken = new CancellationToken();
    //
    //         await handler.Handle(new TransactionBehaviorTestsRequest(), cancellationToken,
    //             () => Task.Run(() => new TransactionBehaviorTestsResponse(), cancellationToken));
    //
    //         transaction.Verify(d => d.CommitAsync(cancellationToken), Times.Once);
    //     }
    //
    //     [Fact]
    //     public async Task Handle_CallNext()
    //     {
    //         (_, TransactionBehavior<TransactionBehaviorTestsRequest, TransactionBehaviorTestsResponse> handler, _) =
    //             Setup();
    //         var cancellationToken = new CancellationToken();
    //         var response = new TransactionBehaviorTestsResponse();
    //         var next = new Mock<RequestHandlerDelegate<TransactionBehaviorTestsResponse>>();
    //         next.Setup(n => n()).ReturnsAsync(response);
    //
    //         var result = await handler.Handle(new TransactionBehaviorTestsRequest(), cancellationToken, next.Object);
    //
    //         next.Verify(n => n(), Times.Once);
    //         Assert.Equal(response, result);
    //     }
    //
    //     private static (Mock<DatabaseFacade> db,
    //         TransactionBehavior<TransactionBehaviorTestsRequest, TransactionBehaviorTestsResponse> handler,
    //         Mock<IDbContextTransaction> transaction) Setup()
    //     {
    //         (Mock<DatabaseFacade> db, Mock<RepairContext> context, Mock<IDbContextTransaction> transaction) =
    //             MockContext.Create();
    //
    //         var handler =
    //             new TransactionBehavior<TransactionBehaviorTestsRequest, TransactionBehaviorTestsResponse>(
    //                 context.Object);
    //
    //         return (db, handler, transaction);
    //     }
    //
    //     public class TransactionBehaviorTestsResponse { }
    //
    //     public class TransactionBehaviorTestsRequest : ICommand { }
}