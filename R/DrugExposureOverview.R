#' @export
createDrugExposureOverview <- function(connectionDetails,
                                       cdmDatabaseSchema,
                                       oracleTempSchema = cdmDatabaseSchema,
                                       resultsSchema,
                                       includeDescendants = FALSE,
                                       drugConceptIds = c()) {
  if (length(drugConceptIds) <= 0) {
    stop("You must provide at least 1 drug concept id")
  }
  connection <- DatabaseConnector::connect(connectionDetails)
  
  # Create study cohort table structure:
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "create_drug_exposure_summary.sql",
      packageName = "DrugUtilization",
      dbms = attr(connection, "dbms"),
      oracleTempSchema = oracleTempSchema,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsSchema = resultsSchema,
      insertConcepts = .insertConceptsSql(
        connection = connection,
        cdmDatabaseSchema = cdmDatabaseSchema,
        includeDescendants = includeDescendants,
        drugConceptIds = drugConceptIds
      )
    )
  
  # For debuging TODO: remove this
  SqlRender::writeSql(sql, "test.dsql")
  
  DatabaseConnector::executeSql(connection,
                                sql,
                                progressBar = T,
                                reportOverallTime = T)
}

getDrugExposureOverview <- function(connectionDetails,
                                    cdmDatabaseSchema,
                                    oracleTempSchema = cdmDatabaseSchema,
                                    resultsSchema) {
  connection <- DatabaseConnector::connect(connectionDetails)
  
  # Get results
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "get_drug_exposure_summary.sql",
      packageName = "DrugUtilization",
      dbms = attr(connection, "dbms"),
      oracleTempSchema = oracleTempSchema,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsSchema = resultsSchema
    )
  
  return(DatabaseConnector::querySql(connection, sql))
}

getDrugExposureDistribution <- function(connectionDetails,
                                    cdmDatabaseSchema,
                                    oracleTempSchema = cdmDatabaseSchema,
                                    resultsSchema) {
  connection <- DatabaseConnector::connect(connectionDetails)
  
  # Get results
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "get_drug_exposure_distribution.sql",
      packageName = "DrugUtilization",
      dbms = attr(connection, "dbms"),
      oracleTempSchema = oracleTempSchema,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsSchema = resultsSchema
    )
  
  return(DatabaseConnector::querySql(connection, sql))
}