using System;
using System.Threading.Tasks;
using FluentValidation.TestHelper;
using Microsoft.EntityFrameworkCore;
using Time.Database;
using Time.Domain.Commands.Records;
using Time.Domain.Validators.Records;
using Xunit;
using RecordEntity = Time.Database.Entities.Record;

namespace Time.Domain.UnitTests.Validators.Records;

public class DeleteRecordValidatorTests
{
    private readonly TimeQueryContext _context;
    public DeleteRecordValidatorTests()
    {
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
    }
    
    [Fact]
    public async Task Id_Success()
    {
        var validator = new DeleteRecordValidator(_context);
        var command = new DeleteRecordCommand
        {
            Id = 1,
            UserId = "user-id0"
        };
        
        var result = await validator.TestValidateAsync(command);
        
        result.ShouldNotHaveValidationErrorFor(x => x.Id);
    }
    
    [Fact]
    public async Task Id_RecordDoesNotExit_Failure()
    {
        var validator = new DeleteRecordValidator(_context);
        var command = new DeleteRecordCommand
        {
            Id = 4,
            UserId = "user-id0"
        };
        
        var result = await validator.TestValidateAsync(command);
        
        result.ShouldHaveValidationErrorFor(x => x.Id)
            .WithErrorMessage("The time record can only be deleted by the owner.");
    }
    
    [Fact]
    public async Task Id_ExistsForDifferentUser_Failure()
    {
        var validator = new DeleteRecordValidator(_context);
        var command = new DeleteRecordCommand
        {
            Id = 1,
            UserId = "user-id4"
        };
        
        var result = await validator.TestValidateAsync(command);
        
        result.ShouldHaveValidationErrorFor(x => x.Id)
            .WithErrorMessage("The time record can only be deleted by the owner.");
    }
}