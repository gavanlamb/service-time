using AutoMapper;
using Time.Api.V1.Models;
using Time.Domain.Commands.Records;
using Time.Domain.Queries.Records;
using DomainRecord = Time.Domain.Models.Record;

namespace Time.Api.V1.Profiles;

public class RecordsProfiles: Profile
{
    public RecordsProfiles()
    {
        CreateMap<CreateRecord, CreateRecordCommand>()
            .ForMember(dest => dest.Name,  opt => opt.MapFrom(src => src.Name))
            .ForMember(dest => dest.Start,  opt => opt.MapFrom(src => src.Start))
            .ForMember(dest => dest.UserId,  opt => opt.MapFrom((_, _, _, context) => context.Items["UserId"]));
            
        CreateMap<UpdateRecord, UpdateRecordCommand>()
            .ForMember(dest => dest.Id, opt => opt.MapFrom((_, _, _, context) => context.Items["Id"]))
            .ForMember(dest => dest.Name, opt => opt.MapFrom(src => src.Name))
            .ForMember(dest => dest.UserId,  opt => opt.MapFrom((_, _, _, context) => context.Items["UserId"]))
            .ForMember(dest => dest.Start, opt => opt.MapFrom(src => src.Start))
            .ForMember(dest => dest.End, opt => opt.MapFrom(src => src.End));
            
        CreateMap<long, DeleteRecordCommand>()
            .ForMember(dest => dest.Id,  opt => opt.MapFrom(src => src))
            .ForMember(dest => dest.UserId,  opt => opt.MapFrom((_, _, _, context) => context.Items["UserId"]));
            
        CreateMap<long, GetRecordByIdQuery>()
            .ForMember(dest => dest.Id,  opt => opt.MapFrom(src => src))
            .ForMember(dest => dest.UserId,  opt => opt.MapFrom((_, _, _, context) => context.Items["UserId"]));
            
        CreateMap<DomainRecord, Record>()
            .ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.Id))
            .ForMember(dest => dest.Name, opt => opt.MapFrom(src => src.Name))
            .ForMember(dest => dest.Start, opt => opt.MapFrom(src => src.Start))
            .ForMember(dest => dest.End, opt => opt.MapFrom(src => src.End))
            .ForMember(dest => dest.Duration, opt => opt.MapFrom(src =>  src.Duration.HasValue ? src.Duration.Value.TotalSeconds : (double?)null));
    }
}