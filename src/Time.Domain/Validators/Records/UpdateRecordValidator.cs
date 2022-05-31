using FluentValidation;
using Time.Domain.Commands.Records;

namespace Time.Domain.Validators.Records;

public class UpdateRecordValidator : AbstractValidator<UpdateRecordCommand>
{
    public UpdateRecordValidator()
    {
        RuleFor(r => r.Name)
            .NotEmpty().WithMessage("The name cannot be an empty value")
            .MinimumLength(2).WithMessage("The name needs to be 2 characters or more");
            
        RuleFor(r => r.Start)
            .Must(DateTimeOffsetValidator.IsInThePast).WithMessage("The start time must be in the past");
            
        RuleFor(r => r.End)
            .Must(DateTimeOffsetValidator.IsInThePast).WithMessage("The end time must be in the past")
            .Must((command, endDateTime) => command.Start < endDateTime).When(endDateTime => endDateTime.End != null).WithMessage("The end time must be greater than or equal to start time");
    }
}