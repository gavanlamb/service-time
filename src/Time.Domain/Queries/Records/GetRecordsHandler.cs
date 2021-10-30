using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using AutoMapper.QueryableExtensions;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Time.Database;
using Time.Domain.Models;

namespace Time.Domain.Queries.Records
{
    public class GetRecordsHandler: IRequestHandler<GetRecordsQuery, Paged<Record>>
    {
        private readonly TimeContext _context;
        private readonly IMapper _mapper;
        
        public GetRecordsHandler(
            TimeContext context,
            IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<Paged<Record>> Handle(
            GetRecordsQuery request,
            CancellationToken cancellationToken)
        {
            var skip = (request.PageNumber - 1) * request.PageSize;
            var take = request.PageSize;
            var count = _context.Records.Count(r => r.UserId == request.UserId);
            
            var records = await _context
                .Records
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
    }
}
