using System;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using Time.Database;
using Time.Domain.Models;
using RecordEntity = Time.Database.Entities.Record;

namespace Time.Domain.Commands.Records;

public class CreateRecordHandler : ICommandHandler<CreateRecordCommand, Record>
{
    private readonly TimeContext _context;
    private readonly IMapper _mapper;
        
    public CreateRecordHandler(
        TimeContext context,
        IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public async Task<Record> Handle(
        CreateRecordCommand request, 
        CancellationToken cancellationToken)
    {
        var recordEntity = _mapper.Map<RecordEntity>(request);
        recordEntity.Created = DateTimeOffset.UtcNow;
            
        await _context.Records.AddAsync(
            recordEntity, 
            cancellationToken);
        await _context.SaveChangesAsync(
            cancellationToken);
            
        return _mapper.Map<Record>(recordEntity);
    }
}