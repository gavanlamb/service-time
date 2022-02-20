FROM mcr.microsoft.com/dotnet/sdk:6.0-alpine AS base
ARG BUILD_NUMBER=0.0.0.1
ARG PAT
WORKDIR /expensely-time
COPY "Time.sln" "Time.sln"
COPY "src/Time.Api/Time.Api.csproj" "src/Time.Api/"
COPY "src/Time.Database/Time.Database.csproj" "src/Time.Database/"
COPY "src/Time.Database.Migrator/Time.Database.Migrator.csproj" "src/Time.Database.Migrator/"
COPY "src/Time.Domain/Time.Domain.csproj" "src/Time.Domain/"
COPY "tests/Time.Domain.UnitTests/Time.Domain.UnitTests.csproj" "tests/Time.Domain.UnitTests/"
COPY "build/nuget.config" "nuget.config"
RUN dotnet restore Time.sln 
COPY . .
RUN dotnet build -c Release /p:Version=$BUILD_NUMBER /p:AssemblyVersion=$BUILD_NUMBER /p:FileVersion=$BUILD_NUMBER


FROM base AS test
WORKDIR /expensely-time
ENTRYPOINT dotnet test --collect:"XPlat Code Coverage" --no-build --configuration Release --results-directory /artifacts/tests/Time.Domain.UnitTests tests/Time.Domain.UnitTests/Time.Domain.UnitTests.csproj --settings tests/default.runsettings


FROM base AS publish-api
RUN dotnet publish "src/Time.Api/Time.Api.csproj" -c Release -o /app/publish --no-build

FROM mcr.microsoft.com/dotnet/aspnet:6.0-alpine AS api
WORKDIR /app
COPY --from=publish-api /app/publish .
ENTRYPOINT ["dotnet", "Time.Api.dll"]


FROM base AS publish-migrator
RUN dotnet publish "src/Time.Database.Migrator/Time.Database.Migrator.csproj" -c Release -o /app/publish --no-build 

FROM amazon/aws-lambda-dotnet:6 AS migrator
WORKDIR /var/task/
COPY --from=publish-migrator /app/publish .
CMD ["Time.Database.Migrator::Time.Database.Migrator.Program::Handler"]

FROM amazon/aws-lambda-dotnet:6.0 AS migrator-local
WORKDIR /var/task/
COPY --from=publish-migrator /app/publish .
ENTRYPOINT ["dotnet", "Time.Database.Migrator.dll"]
