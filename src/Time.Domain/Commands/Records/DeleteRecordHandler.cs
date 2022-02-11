using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Time.Database;

namespace Time.Domain.Commands.Records;

public class DeleteRecordHandler : ICommandHandler<DeleteRecordCommand, bool>
{
    private readonly TimeContext _context;
        
    public DeleteRecordHandler(
        TimeContext context)
    {
        _context = context;
    }
        
    public async Task<bool> Handle(
        DeleteRecordCommand request, 
        CancellationToken cancellationToken)
    {
        var record = _context
            .Records
            .Where(r => r.Id == request.Id)
            .Where(r => r.UserId == request.UserId)
            .FirstOrDefault();

        if (record != null)
        {
            _context
                .Records
                .Remove(record);
            
            _context.SaveChanges();

            return true;
        }

        return false;
    }
}