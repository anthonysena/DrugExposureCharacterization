#' @export
getNetworkResultsDDLSql <- function(networkSchema = "public") {
  pathToSql <-
    system.file("sql/postgresql/networkSchemaDDL.sql", package = "DrugUtilization")
  return(SqlRender::render(
    sql = SqlRender::readSql(pathToSql),
    networkSchema = networkSchema
  ))
}