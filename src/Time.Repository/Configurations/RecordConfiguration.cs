using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Time.DbContext.Entities;

namespace Time.DbContext.Configurations
{
    public class RecordConfiguration : IEntityTypeConfiguration<Record>
    {
        private readonly bool _seed;
        private readonly IEnumerable<string> _userIds;

        public RecordConfiguration(
            IEnumerable<string> userIds, 
            bool seed)
        {
            _userIds = userIds;
            _seed = seed && userIds != null && userIds.Any();
        }

        public void Configure(
            EntityTypeBuilder<Record> builder)
        {
            if (_seed)
            {
                var records = new List<Record>();
                var i = 1;

                foreach (var userId in _userIds)
                {
                    records.Add(
                        new Record
                        {
                            Id = i,
                            UserId = userId,
                            Name = $"Job {i}",
                            Start = DateTime.UtcNow.AddHours(-1),
                            End = DateTime.UtcNow
                        });
                    i++;
                    
                    records.Add(
                        new Record
                        {
                            Id = i,
                            UserId = userId,
                            Name = $"Job {i}",
                            Start = DateTime.UtcNow.AddHours(-6),
                            End = DateTime.UtcNow.AddHours(-4)
                        });
                    i++;
                    
                    records.Add(
                        new Record
                        {
                            Id = i,
                            UserId = userId,
                            Name = $"Job {i}",
                            Start = DateTime.UtcNow.AddMinutes(-3213),
                            End = DateTime.UtcNow.AddMinutes(-3013)
                        });
                    i++;
                }

                if (records.Any())
                {
                    builder.HasData(records);
                }
            }
        }
    }
}