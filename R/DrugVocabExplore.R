#' @export
createDrugVocabExploration <- function(connectionDetails,
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
  if (!DrugUtilization::isConceptListOfIngredients(deConceptList, drugConceptsOfInterest)) {
    print(knitr::kable(conceptList))
    stop("This function only supports Ingredient concepts. Please review the concept(s) above. Any concepts missing may not exist in the target vocabulary)")
  }
  
  
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
        includeDescendants = TRUE,
        drugConceptIds = drugIngredientConceptIds
      ),
      insertConceptsByIngredient = .insertConceptsByIngredient(
        connection = connection,
        cdmDatabaseSchema = cdmDatabaseSchema,
        drugConceptIds = drugIngredientConceptIds
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
  on.exit(DatabaseConnector::disconnect(connection))
  
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

#' @export
getDrugVocabCombos <- function(connectionDetails,
                               cdmDatabaseSchema,
                               oracleTempSchema = cdmDatabaseSchema,
                               resultsSchema) {
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  
  # Get results
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "get_drug_vocab_combos.sql",
      packageName = "DrugUtilization",
      dbms = attr(connection, "dbms"),
      oracleTempSchema = oracleTempSchema,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsSchema = resultsSchema
    )
  
  return(DatabaseConnector::querySql(connection, sql))
}

