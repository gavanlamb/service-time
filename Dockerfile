FROM mcr.microsoft.com/dotnet/sdk:5.0-alpine AS base
WORKDIR /expensely-time
COPY "Expensely.Time.sln" "Expensely.Time.sln"
COPY "src/Expensely.Time.Api/Expensely.Time.Api.csproj" "src/Expensely.Time.Api/"
COPY "src/Expensely.Time.Domain/Expensely.Time.Domain.csproj" "src/Expensely.Time.Domain/"
COPY "src/Expensely.Time.Migrations/Expensely.Time.Migrations.csproj" "src/Expensely.Time.Migrations/"
COPY "src/Expensely.Time.Repository/Expensely.Time.Repository.csproj" "src/Expensely.Time.Repository/"
COPY "tests/Expensely.Time.Api.IntegrationTests/Expensely.Time.Api.IntegrationTests.csproj" "tests/Expensely.Time.Api.IntegrationTests/"
COPY "tests/Expensely.Time.Repository.UnitTests/Expensely.Time.Repository.UnitTests.csproj" "tests/Expensely.Time.Repository.UnitTests/"
COPY "tests/Expensely.Time.Domain.UnitTests/Expensely.Time.Domain.UnitTests.csproj" "tests/Expensely.Time.Domain.UnitTests/"
RUN dotnet restore Expensely.Time.sln
COPY . .
RUN dotnet build -c Release


FROM base AS test
WORKDIR /expensely-time
ENTRYPOINT dotnet test --collect:"XPlat Code Coverage" --no-build --configuration Release --logger trx --results-directory /artifacts/tests/Expensely.Time.Domain.UnitTests tests/Expensely.Time.Domain.UnitTests/Expensely.Time.Domain.UnitTests.csproj && \ 
dotnet test --collect:"XPlat Code Coverage" --no-build --configuration Release --logger trx --results-directory /artifacts/tests/Expensely.Time.Repository.UnitTests tests/Expensely.Time.Repository.UnitTests/Expensely.Time.Repository.UnitTests.csproj && \
dotnet test --no-build --configuration Release --logger trx --results-directory /artifacts/tests/Expensely.Time.Api.IntegrationTests tests/Expensely.Time.Api.IntegrationTests/Expensely.Time.Api.IntegrationTests.csproj


FROM base AS publish-api
RUN dotnet publish "src/Expensely.Time.Api/Expensely.Time.Api.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:5.0-alpine AS api
WORKDIR /app
COPY --from=publish-api /app/publish .
ENTRYPOINT ["dotnet", "Expensely.Time.Api.dll"]


FROM base AS publish-migration
RUN dotnet publish "src/Expensely.Time.Migrations/Expensely.Time.Migrations.csproj" -c Release -o /app/publish

FROM public.ecr.aws/lambda/dotnet:5.0 AS migration
WORKDIR /var/task/
COPY --from=publish-migration /app/publish .
CMD ["ClaimLogikDB::ClaimLogikDB.Function::Handler"]
