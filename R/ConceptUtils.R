#' @export
getConcepts <- function(connection,
                        cdmDatabaseSchema,
                        conceptIds = c()) {
  if (length(conceptIds) <= 0) {
    stop("You must provide at least 1 concept id")
  }

  sql <- SqlRender::readSql(system.file("sql/sql_server/get_concepts.sql", 
                                        package = utils::packageName()))
  return(DatabaseConnector::renderTranslateQuerySql(connection = connection, 
                                                    sql = sql,
                                                    cdm_database_schema = cdmDatabaseSchema,
                                                    concept_ids = conceptIds,
                                                    snakeCaseToCamelCase = TRUE))
}

#' @export
isConceptListOfIngredients <- function(concepts,
                                       conceptIds) {
  return (nrow(concepts[concepts$conceptClassId == "Ingredient" & 
                          concepts$standardConcept == "S",]) == length(conceptIds))
}

#' @export
getDrugIngredientConcepts <- function(connection,
                                      cdmDatabaseSchema) {
  
  sql <- SqlRender::readSql(system.file("sql/sql_server/get_drug_ingredient_concepts.sql", 
                                        package = utils::packageName()))
  return(DatabaseConnector::renderTranslateQuerySql(connection = connection, 
                                                    sql = sql,
                                                    cdm_database_schema = cdmDatabaseSchema,
                                                    snakeCaseToCamelCase = TRUE))
}