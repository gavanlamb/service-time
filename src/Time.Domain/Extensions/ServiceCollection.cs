using MediatR;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Time.Database.Extensions;
using Time.Domain.Behaviours;

namespace Time.Domain.Extensions
{
    public static class ServiceCollection
    {
        public static IServiceCollection AddTimeDomain(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            services.AddAutoMapper(typeof(ServiceCollection));
            
            services.AddTimeContext(configuration);
            services.AddMediatR(typeof(ServiceCollection));
            services.AddTransient(typeof(IPipelineBehavior<,>), typeof(Logging<,>));
            services.AddTransient(typeof(IPipelineBehavior<,>), typeof(Validation<,>));
            services.AddTransient(typeof(IPipelineBehavior<,>), typeof(Transaction<,>));
            
            return services;
        }
    }
}