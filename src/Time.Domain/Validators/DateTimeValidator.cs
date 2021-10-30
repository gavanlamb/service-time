using System;

namespace Time.Domain.Validators
{
    public static class DateTimeValidator
    {
        public static bool BeInThePast(DateTime? date) => date == null || BeInThePast(date);
        
        public static bool BeInThePast(DateTime date) => date.ToUniversalTime() < DateTime.UtcNow;
    }
}