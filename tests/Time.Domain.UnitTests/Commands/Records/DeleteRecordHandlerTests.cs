using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Time.Database;
using Time.Domain.Commands.Records;
using Xunit;
using RecordDomain = Time.Domain.Models.Record;
using RecordEntity = Time.Database.Entities.Record;

namespace Time.Domain.UnitTests.Commands.Records
{
    public class DeleteRecordHandlerTests
    {
        private readonly TimeContext _context;
        private readonly DeleteRecordHandler _handler;

        public DeleteRecordHandlerTests()
        {
            var options = new DbContextOptionsBuilder<TimeContext>()
                .UseInMemoryDatabase(Guid.NewGuid().ToString())
                .Options;
            
            _context = new TimeContext(options);
            _context.Records.Add(new RecordEntity
            {
                Id = 1,
                Name = "One",
                UserId = "user-id0",
                Start = DateTime.UtcNow.AddDays(-3),
                End = DateTime.UtcNow,
                Created = DateTime.UtcNow.AddDays(-3),
                Modified = DateTime.UtcNow,
                Duration = DateTime.UtcNow - DateTime.UtcNow.AddDays(-3)
            });
            _context.SaveChanges();
                
            _handler = new DeleteRecordHandler(_context);
        }
        
        [Fact]
        public async Task Success()
        {
            var command = new DeleteRecordCommand
            {
                Id = 1,
                UserId = "user-id0"
            };
            
            var hasDeleted = await _handler.Handle(command, CancellationToken.None);

            Assert.True(hasDeleted);
            Assert.Empty(_context.Records);
        }
    }
}