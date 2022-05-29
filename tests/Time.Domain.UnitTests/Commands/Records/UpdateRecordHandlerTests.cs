using System;
using System.Linq;
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

public class UpdateRecordHandlerTests
{
    private readonly IMapper _mapper;
    private readonly TimeCommandContext _context;
    private readonly UpdateRecordHandler _handler;
    public UpdateRecordHandlerTests()
    {
        _mapper = new MapperConfiguration(opts => opts.AddProfile(typeof(RecordProfile))).CreateMapper();
            
        var options = new DbContextOptionsBuilder<TimeCommandContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
            
        _context = new TimeCommandContext(options);
        _context.Records.Add(new RecordEntity
        {
            Id = 1,
            Name = "One",
            UserId = "user-id0",
            Start = DateTimeOffset.UtcNow.AddDays(-3),
            Created = DateTimeOffset.UtcNow.AddDays(-3),
        });
        _context.SaveChanges();
                
        _handler = new UpdateRecordHandler(_context, _mapper);
    }

    [Fact]
    public async Task Success()
    {
        var command = new UpdateRecordCommand
        {
            Id = 1,
            Name = "Next",
            UserId = "user-id0",
            Start = DateTimeOffset.UtcNow.AddDays(-3),
            End = DateTimeOffset.UtcNow
        };
            
        var record = await _handler.Handle(command, CancellationToken.None);
            
        Assert.Equal(command.Id, record.Id);
        Assert.Equal(command.Name, record.Name);
        Assert.Equal(command.Start, record.Start);
        Assert.Equal(command.End, record.End);
        Assert.Equal(command.End-command.Start, record.Duration);
    }

    [Fact]
    public async Task SetDuration_Success()
    {
        var command = new UpdateRecordCommand
        {
            Id = 1,
            Name = "Next",
            UserId = "user-id0",
            Start = DateTimeOffset.UtcNow.AddDays(-3),
            End = null
        };
            
        var record = await _handler.Handle(command, CancellationToken.None);
            
        Assert.Equal(command.Id, record.Id);
        Assert.Equal(command.Name, record.Name);
        Assert.Equal(command.Start, record.Start);
        Assert.Equal(command.End, record.End);
        Assert.Null(record.Duration);
    }
}