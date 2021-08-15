# Time
This service is manage time records

## Infrastructure
### Local
The local infrastructure will start a postgres container and a pgadmin container.  

The postgres table will create a default database with a name of `time` and map the data folder to `./local/database/data/`.  

#### Start
```bash
docker compose -f docker-compose.infrastructure.yml up -d
```

#### Down
```bash
docker compose -f docker-compose.infrastructure.yml down
```

#### Remove
Run if the containers have stopped
```bash
docker compose -f docker-compose.infrastructure.yml rm
```

#### Setup pgadmin
1. Go to [http://localhost:58080/](http://localhost:58080/)
2. Right click on `Servers` go to `Create >>> Server` 
3. Create connection
   1. Go to `Connection`
   2. Set the `Host name/address` field to `db`
   3. Set the `Username` field to `admin` 
   4. Set the `Password` field to `Password21` 
   5. Click save

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
dotnet ef migrations add { migration name } --project Time.Migrations --output-dir Migrations
```