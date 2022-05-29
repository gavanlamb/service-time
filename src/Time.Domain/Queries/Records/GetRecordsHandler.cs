using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using AutoMapper.QueryableExtensions;
using Microsoft.EntityFrameworkCore;
using Time.Database;
using Time.Domain.Models;
using RecordEntity = Time.Database.Entities.Record;

namespace Time.Domain.Queries.Records;

public class GetRecordsHandler: IQueryHandler<GetRecordsQuery, Paged<Record>>
{
    private readonly TimeQueryContext _context;
    private readonly IMapper _mapper;
        
    public GetRecordsHandler(
        TimeQueryContext context,
        IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public async Task<Paged<Record>> Handle(
        GetRecordsQuery request,
        CancellationToken cancellationToken)
    {
        var skip = request.PageNumber > 0 ? (request.PageNumber - 1) * request.PageSize : 0; 
        var take = request.PageSize;
        var count = GetTypeClause(
                _context.Records.AsQueryable(), 
                request.Type)
            .Count(r => r.UserId == request.UserId);

        var records = await GetTypeClause(
                _context.Records, 
                request.Type)
            .Where(r => r.UserId == request.UserId)
            .OrderByDescending(r => r.Start)
            .Skip(skip)
            .Take(take)
            .ProjectTo<Record>(_mapper.ConfigurationProvider)
            .ToListAsync(cancellationToken);

        return new Paged<Record>
        {
            PageNumber = request.PageNumber,
            PageSize = records.Count,
            TotalItems = count,
            TotalPages = (int)Math.Ceiling(count / (double)request.PageSize),
            Items = records
        };
    }

    private static IQueryable<RecordEntity> GetTypeClause(
        IQueryable<RecordEntity> record,
        RecordType type)
    {
        return type switch
        {
            RecordType.All => record,
            RecordType.Closed => record.Where(r => r.Duration != null),
            RecordType.Open => record.Where(r => r.Duration == null)
        };
    }
}