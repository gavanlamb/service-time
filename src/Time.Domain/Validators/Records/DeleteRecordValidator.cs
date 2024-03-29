using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Time.Database;
using Time.Domain.Commands.Records;

namespace Time.Domain.Validators.Records;

public class DeleteRecordValidator : AbstractValidator<DeleteRecordCommand>
{
    private readonly TimeQueryContext _context;
    public DeleteRecordValidator(
        TimeQueryContext context)
    {
        _context = context;
            
        RuleFor(r => r.Id)
            .MustAsync(DoesRecordExistForUser).WithMessage("The time record can only be deleted by the owner.");
    }

    private async Task<bool> DoesRecordExistForUser(
        DeleteRecordCommand command, 
        long id,
        CancellationToken cancellationToken) =>
        await _context
            .Records
            .AsNoTracking()
            .AnyAsync(x => x.Id == id && x.UserId == command.UserId, cancellationToken);
}