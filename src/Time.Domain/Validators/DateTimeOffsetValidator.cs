using System;

namespace Time.Domain.Validators
{
    public static class DateTimeOffsetValidator
    {
        public static bool BeInThePast(DateTimeOffset? date) => date == null || BeInThePast(date.Value);
        
        public static bool BeInThePast(DateTimeOffset date) => date.ToUniversalTime() < DateTimeOffset.UtcNow;
    }
}