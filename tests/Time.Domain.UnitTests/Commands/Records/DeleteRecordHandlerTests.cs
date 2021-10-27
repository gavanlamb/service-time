using System;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Moq;
using Time.Database;
using Time.Domain.Commands.Records;
using Xunit;
using RecordDomain = Time.Domain.Models.Record;
using RecordEntity = Time.Database.Entities.Record;

namespace Time.Domain.UnitTests.Commands.Records
{
    public class DeleteRecordHandlerTests
    {
        private readonly Mock<IMapper> _mapper;
        private readonly TimeContext _context;
        private readonly DeleteRecordHandler _handler;

        public DeleteRecordHandlerTests()
        {
            _mapper = new Mock<IMapper>();
            _mapper.Setup(x => x.Map<RecordEntity>(It.IsAny<CreateRecordCommand>()))
                .Returns((CreateRecordCommand a) => new RecordEntity
                {
                    Name = a.Name, 
                    Start = a.Start, 
                    UserId = a.UserId
                });
            _mapper.Setup(x => x.Map<RecordDomain>(It.IsAny<RecordEntity>()))
                .Returns((RecordEntity a) => new RecordDomain
                {
                    Id = a.Id, 
                    Duration = a.Duration,
                    Name = a.Name, 
                    Start = a.Start, 
                    UserId = a.UserId,
                    End = a.End
                });
            
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
                Id = 1
            };
            
            var hasDeleted = await _handler.Handle(command, CancellationToken.None);

            Assert.True(hasDeleted);
            Assert.Empty(_context.Records);
        }
    }
}