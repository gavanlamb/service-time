using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Time.Database;
using Time.Domain.Models;

namespace Time.Domain.Commands.Records;

public class UpdateRecordHandler : ICommandHandler<UpdateRecordCommand, Record>
{
    private readonly TimeCommandContext _context;
    private readonly IMapper _mapper;
        
    public UpdateRecordHandler(
        TimeCommandContext context,
        IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public async Task<Record> Handle(
        UpdateRecordCommand request, 
        CancellationToken cancellationToken)
    {
        var record = await _context
            .Records
            .Where(r => r.Id == request.Id)
            .Where(r => r.UserId == request.UserId)
            .FirstAsync(cancellationToken);
            
        record.Name = request.Name;
        record.Start = request.Start.ToUniversalTime();
        record.End = request.End?.ToUniversalTime();
        record.Modified = DateTimeOffset.UtcNow;

        if (record.End != null)
            record.Duration = request.End - request.Start;
        else
            record.Duration = null;

        var result = await _context.SaveChangesAsync(
            cancellationToken);
            
        return result == 1 ? _mapper.Map<Record>(record) : null;
    }
}