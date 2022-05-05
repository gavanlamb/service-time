# Time
This service is manage time records

## Infrastructure
### AWS

## Pipelines
### Build
The build pipeline will build all assets and push them to ECR.

### Release
Will be triggered from a build and only if it is the main branch. Generally this will be reserved for predefined environments.

### Create preview
Will be triggered from a build and only if it is a pull request merge branch.

### Destroy preview
Will be triggered when there is a push to the main branch.

## Database

## Application
### Setup
Install the dotnet tools that have been defined in [dotnet-tools.json](./config/dotnet-tools.json).   
```bash
dotnet tool restore
```
Any dotnet tools used in the development of this application must be specified in [dotnet-tools.json](./config/dotnet-tools.json).   

### Migrations 
#### Add migration
Run the migration from the `src` folder 
```bash
cd src
dotnet ef migrations add { migration name } --output-dir Migrations --startup-project ./Time.Database.Migrator --project ./Time.Database
```

https://github.com/mattfrear/Swashbuckle.AspNetCore.Filters#add-authorization-to-summary


# TODO
* API & Load tests
  * Look at moving the api tests to a separate repo and generalising the runner
    * Download tests from S3
    * Download config from s3
  * Environment variable 
    * baseurl
    * path for results in s3
  * Must work locally 
