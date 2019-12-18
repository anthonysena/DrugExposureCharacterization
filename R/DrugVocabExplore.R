#' @export
createDrugVocabExploration <- function(connectionDetails,
                                       cdmDatabaseSchema,
                                       oracleTempSchema = cdmDatabaseSchema,
                                       resultsSchema,
                                       includeDescendants = FALSE,
                                       drugConceptIds = c(),
                                       debug = F,
                                       debugSqlFile = "") {
  if (length(drugConceptIds) <= 0) {
    stop("You must provide at least 1 drug concept id")
  }
  if (debug && debugSqlFile == "") {
    stop("When using the debug feature, you must provide a file name for the rendered and translated SQL.")
  }
  connection <- DatabaseConnector::connect(connectionDetails)
  
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "create_drug_vocab_exploration.sql",
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
  
  if (debug) {
    SqlRender::writeSql(sql, debugSqlFile)
  } else {
    DatabaseConnector::executeSql(connection,
                                  sql,
                                  progressBar = T,
                                  reportOverallTime = T)
  }
}

#' @export
getDrugExposureSourceMap <- function(connectionDetails,
                                     cdmDatabaseSchema,
                                     oracleTempSchema = cdmDatabaseSchema,
                                     resultsSchema) {
  connection <- DatabaseConnector::connect(connectionDetails)
  
  # Get results
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "get_drug_exposure_source_map.sql",
      packageName = "DrugUtilization",
      dbms = attr(connection, "dbms"),
      oracleTempSchema = oracleTempSchema,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsSchema = resultsSchema
    )
  
  return(DatabaseConnector::querySql(connection, sql))
}

