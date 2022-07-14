# DrugExposureCharacterization

# Introduction
This R package contains resources for the evaulation of drug exposures in the OMOP CDM for performing drug utilization studies.

# Example
- Download and open the R package using RStudio. 
- Create the file `.Renviron` in the root of the package to hold the settings for connecting to the CDM for performing the drug utilization summary.

````
# --------------------------------
# ------ CDM CONNECTION ----------
# --------------------------------
DBMS = "postgresql"
DB_SERVER = "myserver/db"
DB_PORT = 5432
DB_USER = databaseUserName
DB_PASSWORD = superSecretPassword
CDM_SCHEMA_LIST = "CDM_1,CDM_2,CDM_3"
RESULTS_SCHEMA_LIST = "CDM_1_results,CDM_2_results,CDM_3_results"
DATABASE_LIST = "CDM 1,CDM 2,CDM 3"
# --------------------------------
# -- NETWORK RESULTS CONNECTION --
# --------------------------------
NETWORK_DBMS = "postgresql"
NETWORK_DB_SERVER = "myserver/dus"
NETWORK_DB_PORT = 5432
NETWORK_DB_USER = dbUser
NETWORK_DB_PASSWORD = dbPassword
NETWORK_SCHEMA = "public"
````

The `CDM_SCHEMA_LIST`, `RESULTS_SCHEMA_LIST`, `DATABASE_LIST` can be used to specify a list of CDM schemas to use when generating the results if required.

5. Build the package.

## Usage

The package provides functions to perform the drug exposure summary and for assembling results for sharing over the network.

**Refer to the `extras/TestCode.R` code in the package to see working examples for each of these.**

1.   Create a drug exposure summary in the results schema of your CDM for a list of `drugIngredientConceptIds`:

````
DrugExposureCharacterization::createDrugExposureOverview(
    connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsSchema = resultsSchema,
    drugIngredientConceptIds = drugConceptsOfInterest,
    debug = debug,
    debugSqlFile = "test.dsql"
  )
````

The `debug` setting is used when you'd like to emit the SQL to a file vs. running it directly on your CDM.

2. Export the results from the results schema to the local file system as CSVs:

````
    DrugExposureCharacterization::exportResultsToCSV(
      connectionDetails,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsSchema = resultsSchema,
      outputFolder = outputFolder,
      sourceId = sourceId,
      sourceName = databaseName
    )
````

The `sourceId` and `sourceName` parameters are required but allow for users to define a list of sources for coordination across the network. When using the export, the assumption is that these results will be shared amongst the network of databases that are participating in a study and therefore the DBs will be uniquely identified by their `sourceId` and `sourceName`.

3. Create a PostgreSQL network database & schema to hold the results

````
networkDDLSql <- DrugExposureCharacterization::getNetworkResultsDDLSql(networkSchema = networkSchema)
DatabaseConnector::executeSql(connection = networkDbConnection, sql = networkDDLSql)
````

The code above will create the necessary tables & views in the PostgreSQL database. This will hold the results from across the network.

4. Load the data into the network schema

Refer to the `extras/TestCode.R` code in the package to see how this is scripted. 

# Technology

DrugExposureCharacterization is an R package.

# System requirements

Requires R (version 3.6.0 or higher).

# Getting Started

1.  Make sure your R environment is properly configured. This means that Java must be installed. See [these instructions](https://ohdsi.github.io/Hades/rSetup.html) for how to configure your R environment.

2.  In R, use the following commands to download and install DrugExposureCharacterization:

    ``` r
    remotes::install_github("OHDSI/DrugExposureCharacterization")
    ```

## Development
DrugExposureCharacterization is being developed in R Studio.

**Development Status**

Alpha
