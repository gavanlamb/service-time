using System;
using AutoMapper;
using Time.Domain.Commands.Records;
using Time.Domain.Models;
using RecordEntity = Time.Database.Entities.Record;

namespace Time.Domain.Profiles;

public class RecordProfile : Profile
{
    public RecordProfile()
    {
        CreateMap<CreateRecordCommand, RecordEntity>()
            .ForMember(dest => dest.Id, opt => opt.Ignore())
            .ForMember(dest => dest.End, opt => opt.Ignore())
            .ForMember(dest => dest.Duration, opt => opt.Ignore())
            .ForMember(dest => dest.Start, opt => opt.MapFrom(src => src.Start.ToUniversalTime()))
            .ForMember(dest => dest.Created, opt => opt.MapFrom(_ => DateTimeOffset.UtcNow))
            .ForMember(dest => dest.Modified, opt => opt.Ignore());

        CreateMap<RecordEntity, Record>();
    }
}