using System;

namespace Time.Domain.Validators;

public static class DateTimeOffsetValidator
{
    public static bool IsInThePast(DateTimeOffset? date) => date == null || IsInThePast(date.Value);
        
    public static bool IsInThePast(DateTimeOffset date) => date.ToUniversalTime() < DateTimeOffset.UtcNow;
}