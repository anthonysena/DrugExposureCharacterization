#' @export
getNetworkResultsDDLSql <- function(networkSchema = "public") {
  pathToSql <-
    system.file("sql/postgresql/networkSchemaDDL.sql", package = "DrugUtilization")
  return(SqlRender::render(
    sql = SqlRender::readSql(pathToSql),
    networkSchema = networkSchema
  ))
}

#' @export
getNetworkResultsViewSql <- function(networkSchema = "public") {
  pathToSql <-
    system.file("sql/postgresql/networkSchemaView.sql", package = "DrugUtilization")
  return(SqlRender::render(
    sql = SqlRender::readSql(pathToSql),
    networkSchema = networkSchema
  ))
}

#' @export
getNetworkResultsIndexSql <- function(networkSchema = "public") {
  pathToSql <-
    system.file("sql/postgresql/networkSchemaIndex.sql", package = "DrugUtilization")
  return(SqlRender::render(
    sql = SqlRender::readSql(pathToSql),
    networkSchema = networkSchema
  ))
}