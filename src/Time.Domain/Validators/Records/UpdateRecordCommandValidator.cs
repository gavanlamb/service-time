using FluentValidation;
using Time.Domain.Commands.Records;

namespace Time.Domain.Validators.Records;

public class UpdateRecordCommandValidator : AbstractValidator<UpdateRecordCommand>
{
    public UpdateRecordCommandValidator()
    {
        RuleFor(r => r.Name)
            .NotEmpty().WithMessage("The name cannot be an empty value")
            .MinimumLength(2).WithMessage("The name needs to be 2 characters or more");
            
        RuleFor(r => r.Start)
            .Must(DateTimeOffsetValidator.BeInThePast).WithMessage("The start time must be in the past");
            
        RuleFor(r => r.End)
            .Must(DateTimeOffsetValidator.BeInThePast).When(r => r.End != null).WithMessage("The end time must be in the past");
            
        // TODO Check Start < End
    }
}