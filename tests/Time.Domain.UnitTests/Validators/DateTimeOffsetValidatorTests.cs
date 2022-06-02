using System;
using Time.Domain.Validators;
using Xunit;

namespace Time.Domain.UnitTests.Validators;

public class DateTimeOffsetValidatorTests
{
    [Fact]
    public void DateTimeOffsetNull_Success()
    {
        var isInThePast = DateTimeOffsetValidator.IsInThePast(null);
        
        Assert.True(isInThePast);
    }
    
    [Fact]
    public void DateTimeOffsetNullable_Success()
    {
        DateTimeOffset? dateTime = DateTimeOffset.Now.AddMinutes(-5);
        var isInThePast = DateTimeOffsetValidator.IsInThePast(dateTime);
        
        Assert.True(isInThePast);
    }
    
    [Fact]
    public void DateTimeOffset_Success()
    {
        var dateTime = DateTimeOffset.Now.AddMinutes(-5);
        var isInThePast = DateTimeOffsetValidator.IsInThePast(dateTime);
        
        Assert.True(isInThePast);
    }
    
    [Fact]
    public void DateTimeOffsetNullable_Failure()
    {
        DateTimeOffset? dateTime = DateTimeOffset.Now.AddMinutes(5);
        var isInThePast = DateTimeOffsetValidator.IsInThePast(dateTime);
        
        Assert.False(isInThePast);
    }
    
    [Fact]
    public void DateTimeOffset_Failure()
    {
        var dateTime = DateTimeOffset.Now.AddMinutes(5);
        var isInThePast = DateTimeOffsetValidator.IsInThePast(dateTime);
        
        Assert.False(isInThePast);
    }
}