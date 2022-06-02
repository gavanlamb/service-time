using System.Diagnostics.CodeAnalysis;
using Microsoft.Extensions.Options;
using Time.Database.Options;

namespace Time.Database.Seeds;

[ExcludeFromCodeCoverage]
public class Runner
{
    private readonly RecordSeeds _recordSeeds;
    private readonly Seed _seedOptions;

    public Runner(
        RecordSeeds recordSeeds,
        IOptions<Seed> seedOptions)
    {
        _recordSeeds = recordSeeds;
        _seedOptions = seedOptions.Value;
    }

    public void Run()
    {
        if (_seedOptions.Run)
        {
            _recordSeeds.Add();
        }
    }
}