using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Time.Repository;

namespace Time.Migrations
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly TimeDbContext _context;

        public Worker(
            ILogger<Worker> logger,
            TimeDbContext context)
        {
            _logger = logger;
            _context = context;
        }

        protected override async Task ExecuteAsync(
            CancellationToken stoppingToken)
        {
            await _context.Database.MigrateAsync(stoppingToken);
        }
    }
}