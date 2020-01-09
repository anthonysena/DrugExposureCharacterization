# ------------------------------------------------------------------------
# Get settings from .Renviron
# ------------------------------------------------------------------------
user <- if(Sys.getenv("DB_USER")=="") NULL else Sys.getenv("DB_USER")
password <- if(Sys.getenv("DB_PASSWORD")=="") NULL else Sys.getenv("DB_PASSWORD")
cdmDatabaseSchemaList <- as.vector(strsplit(Sys.getenv("CDM_SCHEMA_LIST"), ",")[[1]])
resultsSchemaList <- as.vector(strsplit(Sys.getenv("RESULTS_SCHEMA_LIST"), ",")[[1]])
databaseList <- as.vector(strsplit(Sys.getenv("DATABASE_LIST"), ",")[[1]])
outputFolder <- getwd()

if (
    length(cdmDatabaseSchemaList) != length(resultsSchemaList) || 
    length(resultsSchemaList) != length(databaseList)
    ) {
  stop("The CDM, results and database lists match in length")
}

# ------------------------------------------------------------------------
# Define the drugs of interest for characterization 
# !! MUST BE RxNORM Ingredients !!
#
# ATC => RXNORM
# cimetidine (A02BA01) + cimetidine, combinations (A02BA51) => 997276
# ranitidine (A02BA02) + ranitidine bismuth citrate (A02BA07) => 	961047
# famotidine (A02BA03) + famotidine, combinations (A02BA53) => 953076
# nizatidine (A02BA04) => 950696
# roxatidine (A02BA06) => 19011685
# lafutidine (A02BA08) => 43009003
#-------------------------------------------------------------------------
drugConceptsOfInterest <- c(997276, 961047, 953076, 950696, 19011685, 43009003)

# ------------------------------------------------------------------------
# Create the drug exposure summary in the results schema & export to CSV
# ------------------------------------------------------------------------

# Connect to the server
connectionDetails <-
  DatabaseConnector::createConnectionDetails(
    dbms = Sys.getenv("DBMS"),
    server = Sys.getenv("DB_SERVER"),
    user = user,
    password = password,
    port = Sys.getenv("DB_PORT")
  )

# Loop through the sources and create a Drug Exposure Overview --------------
debug <- FALSE; # Use this when you'd like to emit the SQL for debugging
export <- TRUE; # Use this when you'd like to control when to export to CSV

for (sourceId in 1:length(cdmDatabaseSchemaList)) {
  cdmDatabaseSchema <- cdmDatabaseSchemaList[sourceId]
  resultsSchema <- resultsSchemaList[sourceId]
  databaseName <- databaseList[sourceId]

  print(paste("Create summary", databaseName))
  
  # Create exposure overview
  DrugUtilization::createDrugExposureOverview(
    connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsSchema = resultsSchema,
    drugIngredientConceptIds = drugConceptsOfInterest,
    debug = debug,
    debugSqlFile = "test.dsql"
  )
  
  if (export) {
    # Export the results
    DrugUtilization::exportResultsToCSV(
      connectionDetails,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsSchema = resultsSchema,
      outputFolder = outputFolder,
      sourceId = sourceId,
      sourceName = databaseName
    )
  }
}

# ------------------------------------------------------------------------
# Create the drug exposure summary in the results schema & export to CSV
# ------------------------------------------------------------------------

# Connect to the network database
networkDbConnectionDetails <-
  DatabaseConnector::createConnectionDetails(
    dbms = Sys.getenv("NETWORK_DBMS"),
    server = Sys.getenv("NETWORK_DB_SERVER"),
    user = Sys.getenv("NETWORK_DB_USER"),
    password = Sys.getenv("NETWORK_DB_PASSWORD"),
    port = Sys.getenv("NETWORK_DB_PORT")
  )

networkDbConnection <- DatabaseConnector::connect(networkDbConnectionDetails)
networkSchema <- Sys.getenv("NETWORK_SCHEMA")

# Establish the network schema's tables
networkDDLSql <- DrugUtilization::getNetworkResultsDDLSql(networkSchema = networkSchema)
SqlRender::writeSql(sql=networkDDLSql, "network.sql")
DatabaseConnector::executeSql(connection = networkDbConnection, sql = networkDDLSql)

# Establish the network schema's views
networkViewSql <- DrugUtilization::getNetworkResultsViewSql(networkSchema = networkSchema)
SqlRender::writeSql(sql=networkViewSql, "network_views.sql")
DatabaseConnector::executeSql(connection = networkDbConnection, sql = networkViewSql)

# Loop through the results and load to the network database --------------
# Get the folders in the output
rootFolder <- file.path(paste0(outputFolder, "/export"))
resultsFolders <- list.dirs(rootFolder, recursive = FALSE)

# Create empty collections for the import
dfConceptColClasses=c("integer",
                      "character",
                      "character",
                      "character",
                      "character",
                      "character",
                      "character",
                      "Date",
                      "Date",
                      "character"
                      )
dfConcept <- data.frame()
dfDeDataPresenceColClasses=c("integer",
                             "integer",
                             "integer",
                             "numeric",
                             "character",
                             "integer",
                             "integer",
                             "integer",
                             "integer",
                             "Date",
                             "Date"
                             )
dfDeDataPresence <- data.frame()
dfDeDetailColClasses=c("integer",
                       "integer",
                       "integer",
                       "integer",
                       "integer",
                       "integer",
                       "integer",
                       "Date",
                       "Date"
)
dfDeDetail <- data.frame()
dfDeOverviewColClasses=c("integer",
                         "integer",
                         "integer",
                         "integer",
                         "Date",
                         "Date"
)
dfDeOverview <- data.frame()
dfDrugConceptXrefColClasses=c("integer",
                              "integer",
                              "integer",
                              "integer",
                              "integer",
                              "numeric",
                              "integer",
                              "numeric",
                              "integer",
                              "numeric",
                              "integer",
                              "integer",
                              "Date",
                              "Date",
                              "character"
)
dfDrugConceptXref <- data.frame()
dfSource <- data.frame()

for (i in 1:length(resultsFolders)) {
  folder <- resultsFolders[i]
  # Concept
  concept <- read.csv(paste0(folder, "/concept.csv"), colClasses = dfConceptColClasses)
  dfConcept <- rbind(dfConcept, concept)
  # Data Presence
  deDataPresence <- read.csv(paste0(folder, "/dus_de_data_presence.csv"), colClasses = dfDeDataPresenceColClasses)
  dfDeDataPresence <- rbind(dfDeDataPresence, deDataPresence)
  # Detail
  deDetail <- read.csv(paste0(folder, "/dus_de_detail.csv"), colClasses = dfDeDetailColClasses)
  dfDeDetail <- rbind(dfDeDetail, deDetail)
  # Overview
  deOverview <- read.csv(paste0(folder, "/dus_de_overview.csv"), colClasses = dfDeOverviewColClasses)
  dfDeOverview <- rbind(dfDeOverview, deOverview)
  # Drug Concept Xref
  drugConceptXref <- read.csv(paste0(folder, "/dus_drug_concept_xref.csv"), colClasses = dfDrugConceptXrefColClasses)
  dfDrugConceptXref <- rbind(dfDrugConceptXref, drugConceptXref)
  # Source
  source <- read.csv(paste0(folder, "/source.csv"))
  dfSource <- rbind(dfSource, source)
}

# Insert the source
DatabaseConnector::insertTable(connection = networkDbConnection,
                               tableName = paste0(networkSchema, ".source"),
                               data = dfSource,
                               dropTableIfExists = FALSE,
                               createTable = FALSE,
                               tempTable = FALSE,
                               useMppBulkLoad = FALSE)

# Insert the unique concepts
DatabaseConnector::insertTable(connection = networkDbConnection,
                               tableName = paste0(networkSchema, ".concept"),
                               data = unique(dfConcept),
                               dropTableIfExists = FALSE,
                               createTable = FALSE,
                               tempTable = FALSE,
                               useMppBulkLoad = FALSE)

# Insert the other drug exposure summary tables
DatabaseConnector::insertTable(connection = networkDbConnection,
                               tableName = paste0(networkSchema, ".de_data_presence"),
                               data = dfDeDataPresence,
                               dropTableIfExists = FALSE,
                               createTable = FALSE,
                               tempTable = FALSE,
                               useMppBulkLoad = FALSE)

DatabaseConnector::insertTable(connection = networkDbConnection,
                               tableName = paste0(networkSchema, ".de_detail"),
                               data = dfDeDetail,
                               dropTableIfExists = FALSE,
                               createTable = FALSE,
                               tempTable = FALSE,
                               useMppBulkLoad = FALSE)

DatabaseConnector::insertTable(connection = networkDbConnection,
                               tableName = paste0(networkSchema, ".de_overview"),
                               data = dfDeOverview,
                               dropTableIfExists = FALSE,
                               createTable = FALSE,
                               tempTable = FALSE,
                               useMppBulkLoad = FALSE)

DatabaseConnector::insertTable(connection = networkDbConnection,
                               tableName = paste0(networkSchema, ".drug_concept_xref"),
                               data = dfDrugConceptXref,
                               dropTableIfExists = FALSE,
                               createTable = FALSE,
                               tempTable = FALSE,
                               useMppBulkLoad = FALSE)

# Establish the network schema's indicies
networkViewSql <- DrugUtilization::getNetworkResultsIndexSql(networkSchema = networkSchema)
SqlRender::writeSql(sql=networkViewSql, "network_index.sql")
DatabaseConnector::executeSql(connection = networkDbConnection, sql = networkViewSql)

