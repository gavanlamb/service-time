using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;

namespace Time.Database.Options;

[ExcludeFromCodeCoverage]
public class Seed
{
    public bool Run { get; set; }

    public List<string> UserIds { get; set; }
}