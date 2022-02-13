using System.Diagnostics;
using Microsoft.AspNetCore.Http;
using Serilog.Core;
using Serilog.Events;

namespace Expensely.Logging.Serilog.Enrichers
{
    public class OTel : ILogEventEnricher
    {
        private readonly IHttpContextAccessor _contextAccessor;

        public OTel()
            : this((IHttpContextAccessor) new HttpContextAccessor())
        {
        }

        public OTel(IHttpContextAccessor contextAccessor) => this._contextAccessor = contextAccessor;

        public void Enrich(LogEvent logEvent, ILogEventPropertyFactory propertyFactory)
        {
            var activity = Activity.Current;

            if (activity != null)
            {
                logEvent.AddPropertyIfAbsent(new LogEventProperty("RootId", new ScalarValue(activity.RootId)));
                logEvent.AddPropertyIfAbsent(new LogEventProperty("ParentId", new ScalarValue(activity.ParentId)));
                logEvent.AddPropertyIfAbsent(new LogEventProperty("SpanId", new ScalarValue(activity.SpanId)));
                logEvent.AddPropertyIfAbsent(new LogEventProperty("TraceId", new ScalarValue(activity.TraceId)));
            }
        }
    }
}