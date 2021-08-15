FROM mcr.microsoft.com/dotnet/sdk:5.0-alpine AS base
ARG BUILD_NUMBER=0.0.0.1
ARG PAT
WORKDIR /expensely-time
COPY "Time.sln" "Time.sln"
COPY "src/Time.Api/Time.Api.csproj" "src/Time.Api/"
COPY "src/Time.Migrations/Time.Migrations.csproj" "src/Time.Migrations/"
COPY "src/Time.Repository/Time.Repository.csproj" "src/Time.Repository/"
COPY "tests/Time.Api.IntegrationTests/Time.Api.IntegrationTests.csproj" "tests/Time.Api.IntegrationTests/"
COPY "tests/Time.Repository.UnitTests/Time.Repository.UnitTests.csproj" "tests/Time.Repository.UnitTests/"
COPY "build/nuget.config" "nuget.config"
RUN dotnet restore Time.sln 
COPY . .
RUN dotnet build -c Release /p:Version=$BUILD_NUMBER /p:AssemblyVersion=$BUILD_NUMBER /p:FileVersion=$BUILD_NUMBER


FROM base AS test
WORKDIR /expensely-time
ENTRYPOINT dotnet test --collect:"XPlat Code Coverage" --no-build --configuration Release --logger trx --results-directory /artifacts/tests/Time.Repository.UnitTests tests/Time.Repository.UnitTests/Time.Repository.UnitTests.csproj && \
dotnet test --no-build --configuration Release --logger trx --results-directory /artifacts/tests/Time.Api.IntegrationTests tests/Time.Api.IntegrationTests/Time.Api.IntegrationTests.csproj


FROM base AS publish-api
RUN dotnet publish "src/Time.Api/Time.Api.csproj" -c Release -o /app/publish --no-build


FROM mcr.microsoft.com/dotnet/aspnet:5.0-alpine AS api
WORKDIR /app
COPY --from=publish-api /app/publish .
ENTRYPOINT ["dotnet", "Time.Api.dll"]


FROM base AS publish-migration
RUN dotnet publish "src/Time.Migrations/Time.Migrations.csproj" -c Release -o /app/publish --no-build 


FROM amazon/aws-lambda-dotnet:5.0 AS migration
WORKDIR /var/task/
COPY --from=publish-migration /app/publish .
CMD ["Time.Migrations::Time.Migrations.Program::Handler"]


FROM amazon/aws-lambda-dotnet:5.0 AS migration-local
WORKDIR /var/task/
COPY --from=publish-migration /app/publish .
ENTRYPOINT ["dotnet", "Time.Migrations.dll"]
