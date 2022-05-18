using System;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Time.Database;
using Time.Domain.Profiles;
using Time.Domain.Queries.Records;
using Xunit;
using RecordDomain = Time.Domain.Models.Record;
using RecordEntity = Time.Database.Entities.Record;

namespace Time.Domain.UnitTests.Queries.Records;

public class GetRecordByIdHandlerTests 
{
    private readonly IMapper _mapper;
    private readonly TimeQueryContext _context;
    private readonly GetRecordByIdHandler _handler;
    public GetRecordByIdHandlerTests()
    {
        _mapper = new MapperConfiguration(opts => opts.AddProfile(typeof(RecordProfile))).CreateMapper();

        var options = new DbContextOptionsBuilder<TimeQueryContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _context = new TimeQueryContext(options);
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
                
        _handler = new GetRecordByIdHandler(_context, _mapper);
    }

    [Fact]
    public async Task Success()
    {
        var command = new GetRecordByIdQuery
        {
            Id = 1,
            UserId = "user-id0"
        };
            
        var record = await _handler.Handle(command, CancellationToken.None);
            
        Assert.Equal(1, record.Id);
    }
}