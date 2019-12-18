#' @export
getConcepts <- function(connectionDetails,
                        cdmDatabaseSchema,
                        conceptIds = c()) {
  if (length(conceptIds) <= 0) {
    stop("You must provide at least 1 concept id")
  }
  connection <- DatabaseConnector::connect(connectionDetails)
  
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "get_concepts.sql",
      packageName = "DrugUtilization",
      dbms = attr(connection, "dbms"),
      cdmDatabaseSchema = cdmDatabaseSchema,
      conceptIds = conceptIds
    )
  
  
  return(DatabaseConnector::querySql(connection, sql))
}

#' @export
isConceptListOfIngredients <- function(concepts,
                                       conceptIds) {
  return (nrow(concepts[concepts$CONCEPT_CLASS_ID == "Ingredient" & concepts$STANDARD_CONCEPT == "S",]) == length(conceptIds))
}