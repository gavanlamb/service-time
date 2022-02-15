using System;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Time.Database;
using Time.Domain.Commands.Records;
using Time.Domain.Profiles;
using Xunit;
using RecordDomain = Time.Domain.Models.Record;
using RecordEntity = Time.Database.Entities.Record;

namespace Time.Domain.UnitTests.Commands.Records;

public class CreateRecordHandlerTests
{
    private readonly IMapper _mapper;
    private readonly TimeContext _context;
    private readonly CreateRecordHandler _handler;
    public CreateRecordHandlerTests()
    {
        _mapper = new MapperConfiguration(opts => opts.AddProfile(typeof(RecordProfile))).CreateMapper();
            
        var options = new DbContextOptionsBuilder<TimeContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
            
        _context = new TimeContext(options);
        _context.Records.Add(new RecordEntity
        {
            Id = 1,
            Name = "One",
            UserId = "user-id0",
            Start = DateTimeOffset.UtcNow.AddDays(-3),
            End = DateTimeOffset.UtcNow,
            Created = DateTimeOffset.UtcNow.AddDays(-3),
            Modified = DateTimeOffset.UtcNow,
            Duration = DateTimeOffset.UtcNow - DateTimeOffset.UtcNow.AddDays(-3)
        });
        _context.Records.Add(new RecordEntity
        {
            Id = 2,
            Name = "two",
            UserId = "user-id0",
            Start = DateTimeOffset.UtcNow.AddDays(-2),
            End = DateTimeOffset.UtcNow,
            Created = DateTimeOffset.UtcNow.AddDays(-2),
            Modified = DateTimeOffset.UtcNow,
            Duration = DateTimeOffset.UtcNow - DateTimeOffset.UtcNow.AddDays(-2)
        });
        _context.SaveChanges();
                
        _handler = new CreateRecordHandler(_context, _mapper);
    }

    [Fact]
    public async Task Success()
    {
        var command = new CreateRecordCommand
        {
            Name = "Next",
            UserId = "user-id0",
            Start = DateTimeOffset.UtcNow
        };
            
        var record = await _handler.Handle(command, CancellationToken.None);
            
        Assert.Equal(3, record.Id);
        Assert.Equal(command.Name, record.Name);
        Assert.Equal(command.UserId, record.UserId);
        Assert.Equal(command.Start, record.Start);
    }
}