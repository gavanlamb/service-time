using System;
using AutoMapper;
using Time.Domain.Commands.Records;
using Time.Domain.Profiles;
using Xunit;
using RecordDomain = Time.Domain.Models.Record;
using RecordEntity = Time.Database.Entities.Record;

namespace Time.Domain.UnitTests.Profiles
{
    public class RecordProfileTests
    {
        [Fact]
        public void RecordProfileConfiguration()
        {
            var mapper = new MapperConfiguration(opts => opts.AddProfile(typeof(RecordProfile)));

            mapper.AssertConfigurationIsValid();
        }
        
        [Fact]
        public void CreateRecordCommandToRecordEntity()
        {
            var mapper = new MapperConfiguration(opts => opts.AddProfile(typeof(RecordProfile))).CreateMapper();

            var command = new CreateRecordCommand
            {
                UserId = "id",
                Name = "Test",
                Start = new DateTimeOffset(2020, 01, 01, 01, 01, 01, TimeSpan.Zero)
            };

            var record = mapper.Map<RecordEntity>(command);
            Assert.Equal(command.UserId, record.UserId);
            Assert.Equal(command.Name, record.Name);
            Assert.Equal(command.Start, record.Start);
        }
        
        [Fact]
        public void RecordEntityToRecord()
        {
            var mapper = new MapperConfiguration(opts => opts.AddProfile(typeof(RecordProfile))).CreateMapper();

            var recordEntity = new RecordEntity
            {
                Id = 1,
                UserId = "id",
                Name = "Test",
                Duration = new TimeSpan(1,1,1,1),
                Start = new DateTimeOffset(2020, 01, 01, 01, 01, 01, TimeSpan.Zero),
                End = new DateTimeOffset(2020, 01, 01, 01, 01, 59, TimeSpan.Zero)
            };
            
            var recordDomain = mapper.Map<RecordDomain>(recordEntity);
            Assert.Equal(recordDomain.Id, recordEntity.Id);
            Assert.Equal(recordDomain.UserId, recordEntity.UserId);
            Assert.Equal(recordDomain.Name, recordEntity.Name);
            Assert.Equal(recordDomain.Duration, recordEntity.Duration);
            Assert.Equal(recordDomain.Start, recordEntity.Start);
            Assert.Equal(recordDomain.End, recordEntity.End);
        }
    }
}