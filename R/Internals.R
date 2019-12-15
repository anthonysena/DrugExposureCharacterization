.createConceptTempTableSql <- function(connection) {
   return(SqlRender::loadRenderTranslateSql(sqlFilename = "create_concept_temp_table.sql", 
                                            packageName = "DrugUtilization",
                                            dbms = attr(connection, "dbms")));
}

.insertConceptsSql <- function(connection, 
                            cdmDatabaseSchema,
                            includeDescendants,
                            drugConceptIds) {
  return(SqlRender::loadRenderTranslateSql(sqlFilename = "insert_concepts.sql", 
                                           packageName = "DrugUtilization",
                                           dbms = attr(connection, "dbms"),
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           includeDescendants = as.integer(includeDescendants),
                                           conceptIds = drugConceptIds));
}
