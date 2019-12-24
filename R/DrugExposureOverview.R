#' @export
createDrugExposureOverview <- function(connectionDetails,
                                       cdmDatabaseSchema,
                                       oracleTempSchema = cdmDatabaseSchema,
                                       resultsSchema,
                                       drugIngredientConceptIds = c(),
                                       debug = F,
                                       debugSqlFile = "") {
  if (length(drugIngredientConceptIds) <= 0) {
    stop("You must provide at least 1 drug concept id")
  }
  if (debug && debugSqlFile == "") {
    stop("When using the debug feature, you must provide a file name for the rendered and translated SQL.")
  }
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  
  # Verify that only Ingredient concepts are specified
  conceptList <- DrugUtilization::getConcepts(
    connection, 
    cdmDatabaseSchema = cdmDatabaseSchema, 
    conceptIds = drugIngredientConceptIds
  )
  if (!DrugUtilization::isConceptListOfIngredients(conceptList, drugConceptsOfInterest)) {
    print(knitr::kable(conceptList))
    stop("This function only supports Ingredient concepts. Please review the concept(s) above. Any concepts missing may not exist in the target vocabulary)")
  }
  

  # Create the drug exposure summary results  
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "create_drug_exposure_summary.sql",
      packageName = "DrugUtilization",
      dbms = attr(connection, "dbms"),
      oracleTempSchema = oracleTempSchema,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsSchema = resultsSchema,
      insertConceptsByIngredient = .insertConceptsByIngredient(
        connection = connection,
        cdmDatabaseSchema = cdmDatabaseSchema,
        drugConceptIds = drugIngredientConceptIds
      )
    )
  
  if (debug) {
    SqlRender::writeSql(sql, debugSqlFile)
    print(paste0("Debug file written to: ", debugSqlFile))
  } else {
    DatabaseConnector::executeSql(connection,
                                  sql,
                                  progressBar = T,
                                  reportOverallTime = T)
  }
}

.insertConceptsByIngredient <- function(connection, 
                                        cdmDatabaseSchema,
                                        drugConceptIds) {
  return(SqlRender::loadRenderTranslateSql(sqlFilename = "insert_concepts_by_ingredient.sql", 
                                           packageName = "DrugUtilization",
                                           dbms = attr(connection, "dbms"),
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           conceptIds = drugConceptIds));
}
