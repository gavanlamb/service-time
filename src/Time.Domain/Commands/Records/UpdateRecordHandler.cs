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
    private readonly TimeContext _context;
    private readonly IMapper _mapper;
        
    public UpdateRecordHandler(
        TimeContext context,
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
        record.Start = request.Start;
        record.End = request.End;
        record.Modified = DateTimeOffset.UtcNow;
            
        if (record.End != null)
            record.Duration = request.End - request.Start;
            
        await _context.SaveChangesAsync(cancellationToken);
            
        return _mapper.Map<Record>(record);
    }
}