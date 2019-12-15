# Details for connecting to the server:
connectionDetails <-
  DatabaseConnector::createConnectionDetails(
    dbms = Sys.getenv("DBMS"),
    server = Sys.getenv("DB_SERVER"),
    user = NULL,
    password = NULL,
    port = Sys.getenv("DB_PORT")
  )

# Create exposure overview
DrugUtilization::createDrugExposureOverview(
  connectionDetails,
  cdmDatabaseSchema = Sys.getenv("CDM_SCHEMA"),
  resultsSchema = Sys.getenv("RESULTS_SCHEMA"),
  includeDescendants = FALSE,
  drugConceptIds = c(939259, 19060647)
)

# Get exposure overview
deOverview <-
  DrugUtilization::getDrugExposureOverview(
    connectionDetails,
    cdmDatabaseSchema = Sys.getenv("CDM_SCHEMA"),
    resultsSchema = Sys.getenv("RESULTS_SCHEMA")
  )

# Get distributions
deDist <-
  DrugUtilization::getDrugExposureDistribution(
    connectionDetails,
    cdmDatabaseSchema = Sys.getenv("CDM_SCHEMA"),
    resultsSchema = Sys.getenv("RESULTS_SCHEMA")
  )
