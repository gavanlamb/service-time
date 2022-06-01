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

public class ValidationBehaviourTests
{
    [Fact]
    public async Task Handle_NoValidators_CallsNext()
    {
        IEnumerable<IValidator<ValidationBehaviorTestsRequest>> validators = new List<IValidator<ValidationBehaviorTestsRequest>>();
        var next = new Mock<RequestHandlerDelegate<ValidationBehaviorTestsResponse>>();
        var handler = new Validation<ValidationBehaviorTestsRequest, ValidationBehaviorTestsResponse>(validators);
        var cancellationToken = new CancellationToken();
    
        await handler.Handle(new ValidationBehaviorTestsRequest(), cancellationToken, next.Object);
    
        next.Verify(n => n(), Times.Once);
    }
    
    [Fact]
    public async Task Handle_ValidatorReturnsNoError_CallsNext()
    {
        //var validator = new Mock<IValidator>().Setup(x => x.Validate(It.IsAny<IValidationContext>())).Returns(new ValidationResult());
        IEnumerable<IValidator<ValidationBehaviorTestsRequest>> validators = new List<IValidator<ValidationBehaviorTestsRequest>>
        {
            new Validator()
        };
        var next = new Mock<RequestHandlerDelegate<ValidationBehaviorTestsResponse>>();
        var handler = new Validation<ValidationBehaviorTestsRequest, ValidationBehaviorTestsResponse>(validators);
        var cancellationToken = new CancellationToken();
    
        await handler.Handle(new ValidationBehaviorTestsRequest(), cancellationToken, next.Object);
    
        next.Verify(n => n(), Times.Once);
    }
    
    
    [Fact]
    public async Task Handle_ValidatorReturnsError_ThrowsValidationException()
    {
        var validationFailures = new List<ValidationFailure>
        {
            new ("propertyName","propertyName is required")
        };
        var validator = new Mock<IValidator<ValidationBehaviorTestsRequest>>();
        validator.Setup(x => x.ValidateAsync(It.IsAny<IValidationContext>(), It.IsAny<CancellationToken>()))
            .Returns(Task.FromResult(new ValidationResult(validationFailures)));
        var validators = new List<IValidator<ValidationBehaviorTestsRequest>>
        {
            validator.Object
        };
        var next = new Mock<RequestHandlerDelegate<ValidationBehaviorTestsResponse>>();
        var handler = new Validation<ValidationBehaviorTestsRequest, ValidationBehaviorTestsResponse>(validators);
        var cancellationToken = new CancellationToken();
    
        Func<Task> act = async () => await handler.Handle(new ValidationBehaviorTestsRequest(), cancellationToken, next.Object);
    
        await Assert.ThrowsAsync<ValidationException>(() => act());
    }
    
    public class Validator : AbstractValidator<ValidationBehaviorTestsRequest> { }
    
    public class ValidationBehaviorTestsResponse { }
    
    public class ValidationBehaviorTestsRequest : ICommand<ValidationBehaviorTestsResponse> { }
}