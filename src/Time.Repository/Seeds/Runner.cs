using Microsoft.Extensions.Options;
using Time.DbContext.Options;

namespace Time.DbContext.Seeds
{
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
}