using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using FluentValidation.Results;
using MediatR;
using Moq;
using Time.Domain.Behaviours;
using Time.Domain.Commands;
using Xunit;

namespace Time.Domain.UnitTests.Behaviours;

public class ValidationTests
{
    [Fact]
    public async Task Handle_NoValidators_CallsNext()
    {
        IEnumerable<IValidator<ValidationTestsRequest>> validators = new List<IValidator<ValidationTestsRequest>>();
        var next = new Mock<RequestHandlerDelegate<ValidationTestsResponse>>();
        var handler = new Validation<ValidationTestsRequest, ValidationTestsResponse>(validators);
        var cancellationToken = new CancellationToken();
    
        await handler.Handle(new ValidationTestsRequest(), cancellationToken, next.Object);
    
        next.Verify(n => n(), Times.Once);
    }
    
    [Fact]
    public async Task Handle_ValidatorReturnsNoError_CallsNext()
    {
        IEnumerable<IValidator<ValidationTestsRequest>> validators = new List<IValidator<ValidationTestsRequest>>
        {
            new Validator()
        };
        var next = new Mock<RequestHandlerDelegate<ValidationTestsResponse>>();
        var handler = new Validation<ValidationTestsRequest, ValidationTestsResponse>(validators);
        var cancellationToken = new CancellationToken();
    
        await handler.Handle(new ValidationTestsRequest(), cancellationToken, next.Object);
    
        next.Verify(n => n(), Times.Once);
    }
    
    [Fact]
    public async Task Handle_ValidatorReturnsError_ThrowsValidationException()
    {
        var validationFailures = new List<ValidationFailure>
        {
            new ("propertyName","propertyName is required")
        };
        var validator = new Mock<IValidator<ValidationTestsRequest>>();
        validator.Setup(x => x.ValidateAsync(It.IsAny<IValidationContext>(), It.IsAny<CancellationToken>()))
            .Returns(Task.FromResult(new ValidationResult(validationFailures)));
        var validators = new List<IValidator<ValidationTestsRequest>>
        {
            validator.Object
        };
        var next = new Mock<RequestHandlerDelegate<ValidationTestsResponse>>();
        var handler = new Validation<ValidationTestsRequest, ValidationTestsResponse>(validators);
        var cancellationToken = new CancellationToken();
    
        Func<Task> act = async () => await handler.Handle(new ValidationTestsRequest(), cancellationToken, next.Object);
    
        await Assert.ThrowsAsync<ValidationException>(() => act());
    }
    
    public class Validator : AbstractValidator<ValidationTestsRequest> { }
    
    public class ValidationTestsResponse { }
    
    public class ValidationTestsRequest : ICommand<ValidationTestsResponse> { }
}