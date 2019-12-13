#' @export
drugExposureOverview <- function(connectionDetails,
                                 cdmDatabaseSchema,
                                 oracleTempSchema = cdmDatabaseSchema,
                                 resultsSchema,
                                 drugConceptIds = c(),
                                 minCellCount= 5) {
  
  if (length(drugConceptIds) <= 0) {
    stop("You must provide at least 1 drug concept id")
  }
  connection <- DatabaseConnector::connect(connectionDetails)
  
  # Create study cohort table structure:
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "drug_exposure_summary.sql",
                                           packageName = "DrugUtilization",
                                           dbms = attr(connection, "dbms"),
                                           oracleTempSchema = oracleTempSchema,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           resultsSchema = resultsSchema,
                                           conceptIds = drugConceptIds)
  
  # For debuging TODO: remove this
  #SqlRender::writeSql(sql, "drug_exposure_summary.sql")
  
  DatabaseConnector::executeSql(connection, sql, progressBar = T, reportOverallTime = T)
  
  # Get results - TODO: Externalize query
  returnResultsQuery <- SqlRender::translateSingleStatement(
    targetDialect = attr(connection, "dbms"),
    sql = SqlRender::render("SELECT * FROM @resultsSchema.dus_overview ORDER BY total_records desc, concept_id", resultsSchema = resultsSchema)
  )
  
  return(DatabaseConnector::querySql(connection, returnResultsQuery))
}