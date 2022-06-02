using System;
using System.Threading.Tasks;
using FluentValidation.TestHelper;
using Time.Domain.Commands.Records;
using Time.Domain.Validators.Records;
using Xunit;

namespace Time.Domain.UnitTests.Validators.Records;

public class CreateRecordValidatorTests
{
    [Fact]
    public async Task Name_Success()
    {
        var validator = new CreateRecordValidator();
        var command = new CreateRecordCommand
        {
            Name = "Name"
        };
        
        var result = await validator.TestValidateAsync(command);
        
        result.ShouldNotHaveValidationErrorFor(x => x.Name);
    }
    
    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public async Task Name_NotEmpty_Failure(string name)
    {
        var validator = new CreateRecordValidator();
        var command = new CreateRecordCommand
        {
            Name = name
        };
        
        var result = await validator.TestValidateAsync(command);
        
        result
            .ShouldHaveValidationErrorFor(x => x.Name)
            .WithErrorMessage("The name cannot be an empty value");
    }
    
    [Fact]
    public async Task Name_MinimumLength_Failure()
    {
        var validator = new CreateRecordValidator();
        var command = new CreateRecordCommand
        {
            Name = "N"
        };
        
        var result = await validator.TestValidateAsync(command);
        
        result
            .ShouldHaveValidationErrorFor(x => x.Name)
            .WithErrorMessage("The name needs to be 2 characters or more");
    }
    
    [Fact]
    public async Task Start_InThePast_Success()
    {
        var validator = new CreateRecordValidator();
        var command = new CreateRecordCommand
        {
            Name = "Name",
            Start = DateTimeOffset.Now.AddMinutes(-5)
        };
        
        var result = await validator.TestValidateAsync(command);
        
        result.ShouldNotHaveValidationErrorFor(x => x.Start);
    }
    
    [Fact]
    public async Task Start_InThePast_Failure()
    {
        var validator = new CreateRecordValidator();
        var command = new CreateRecordCommand
        {
            Name = "Name",
            Start = DateTimeOffset.Now.AddMinutes(5)
        };
        
        var result = await validator.TestValidateAsync(command);
        
        result
            .ShouldHaveValidationErrorFor(x => x.Start)
            .WithErrorMessage("The start time must be in the past");
    }
}