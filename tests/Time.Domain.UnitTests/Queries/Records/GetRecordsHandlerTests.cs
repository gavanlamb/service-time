using System;
using System.Linq;
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

public class GetRecordsHandlerTests
{
    private const string UserId = "user-id";
    private readonly IMapper _mapper;
    private readonly TimeQueryContext _context;
    private readonly GetRecordsHandler _handler;
    public GetRecordsHandlerTests()
    {
        _mapper = new MapperConfiguration(opts => opts.AddProfile(typeof(RecordProfile))).CreateMapper();

        var options = new DbContextOptionsBuilder<TimeQueryContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _context = new TimeQueryContext(options);
        for (var i = 1; i <= 50; i++) {
            _context.Records.Add(new RecordEntity
            {
                Id = i,
                Name = $"Record name {i}",
                UserId = UserId,
                Start = DateTimeOffset.UtcNow.AddDays(-3),
                End = DateTimeOffset.UtcNow,
                Created = DateTimeOffset.UtcNow.AddDays(-3),
                Modified = DateTimeOffset.UtcNow,
                Duration = DateTimeOffset.UtcNow - DateTimeOffset.UtcNow.AddDays(-3)
            });
        }
        for (var i = 1; i <= 50; i++) {
            _context.Records.Add(new RecordEntity
            {
                Id = i+50,
                Name = $"Record name {i+50}",
                UserId = UserId,
                Start = DateTimeOffset.UtcNow.AddDays(-3),
                Created = DateTimeOffset.UtcNow.AddDays(-3)
            });
        }
        _context.SaveChanges();
                
        _handler = new GetRecordsHandler(_context, _mapper);
    }
        
    [Fact]
    public async Task Success()
    {
        var command = new GetRecordsQuery
        {
            PageNumber = 1,
            PageSize = 5,
            UserId = UserId
        };
            
        var records = await _handler.Handle(command, CancellationToken.None);
            
        Assert.Equal(command.PageNumber, records.PageNumber);
        Assert.Equal(command.PageSize, records.PageSize);
        Assert.Equal(command.PageSize, records.Items.Count());
        Assert.Equal(100, records.TotalItems);
        Assert.Equal(20, records.TotalPages);
    }
        
    [Fact]
    public async Task OutOfBounds_Success()
    {
        var command = new GetRecordsQuery
        {
            PageNumber = 21,
            PageSize = 5,
            UserId = UserId
        };
            
        var records = await _handler.Handle(command, CancellationToken.None);
            
        Assert.Equal(command.PageNumber, records.PageNumber);
        Assert.Equal(0, records.PageSize);
        Assert.Empty(records.Items);
        Assert.Equal(100, records.TotalItems);
        Assert.Equal(20, records.TotalPages);
    }
        
    [Fact]
    public async Task LastPagePartialSize_Success()
    {
        var command = new GetRecordsQuery
        {
            PageNumber = 4,
            PageSize = 30,
            UserId = UserId
        };
            
        var records = await _handler.Handle(command, CancellationToken.None);
            
        Assert.Equal(command.PageNumber, records.PageNumber);
        Assert.Equal(10, records.PageSize);
        Assert.Equal(10, records.Items.Count());
        Assert.Equal(100, records.TotalItems);
        Assert.Equal(4, records.TotalPages);
    }
    
    [Theory]
    [InlineData(RecordType.All, 100, 10)]
    [InlineData(RecordType.Closed, 50, 5)]
    [InlineData(RecordType.Open, 50, 5)]
    public async Task RecordType_Success(
        RecordType type,
        int expectedNumberOfRecords,
        int totalNumberOfPages)
    {
        var command = new GetRecordsQuery
        {
            PageNumber = 1,
            PageSize = 10,
            UserId = UserId,
            Type = type
        };
            
        var records = await _handler.Handle(command, CancellationToken.None);
            
        Assert.Equal(command.PageNumber, records.PageNumber);
        Assert.Equal(10, records.PageSize);
        Assert.Equal(10, records.Items.Count());
        Assert.Equal(expectedNumberOfRecords, records.TotalItems);
        Assert.Equal(totalNumberOfPages, records.TotalPages);
    }
}