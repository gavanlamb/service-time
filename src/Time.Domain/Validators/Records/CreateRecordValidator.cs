using FluentValidation;
using Time.Domain.Commands.Records;

namespace Time.Domain.Validators.Records;

public class CreateRecordValidator : AbstractValidator<CreateRecordCommand>
{
    public CreateRecordValidator()
    {
        RuleFor(r => r.Name)
            .NotEmpty().WithMessage("The name cannot be an empty value")
            .MinimumLength(2).WithMessage("The name needs to be 2 characters or more");
            
        RuleFor(r => r.Start)
            .Must(DateTimeOffsetValidator.IsInThePast).WithMessage("The start time must be in the past");
    }
}