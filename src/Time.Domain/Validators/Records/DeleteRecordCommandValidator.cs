using System.Linq;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Time.Database;
using Time.Domain.Commands.Records;

namespace Time.Domain.Validators.Records;

public class DeleteRecordCommandValidator : AbstractValidator<DeleteRecordCommand>
{
    private readonly TimeContext _context;
    public DeleteRecordCommandValidator(
        TimeContext context)
    {
        _context = context;
            
        RuleFor(r => r.Id)
            .Must(DoesRecordExistForUser).WithMessage("The time record can only be deleted by the owner.");
    }

    private bool DoesRecordExistForUser(
        DeleteRecordCommand command, 
        long id) =>
        _context
            .Records
            .AsNoTracking()
            .Any(x => x.Id == id && x.UserId == command.UserId);
}