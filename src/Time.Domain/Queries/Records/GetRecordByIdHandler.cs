using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using AutoMapper.QueryableExtensions;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Time.Database;
using Time.Domain.Models;
using RecordEntity = Time.Database.Entities.Record;

namespace Time.Domain.Queries.Records;

public class GetRecordByIdHandler : IQueryHandler<GetRecordByIdQuery, Record>
{
    private readonly TimeQueryContext _context;
    private readonly IMapper _mapper;
        
    public GetRecordByIdHandler(
        TimeQueryContext context,
        IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public async Task<Record> Handle(
        GetRecordByIdQuery request, 
        CancellationToken cancellationToken) => await 
        _context
            .Records
            .AsNoTracking()
            .Where(r => r.UserId == request.UserId)
            .Where(r => r.Id == request.Id)
            .ProjectTo<Record>(_mapper.ConfigurationProvider)
            .FirstOrDefaultAsync(cancellationToken);
}