#' @export
exportResultsToCSV <- function(connectionDetails,
                               cdmDatabaseSchema,
                               tempEmulationSchema = getOption("sqlRenderTempEmulationSchema"),
                               resultsDatabaseSchema,
                               outputFolder,
                               databaseId,
                               databaseName) {
  if (is.null(databaseId)) {
    stop("You must provide a database ID to export results.")
  }
  if (is.null(databaseName)) {
    stop("You must provide a name for the database.")
  }
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  
  if (!dir.exists(outputFolder)) {
    dir.create(outputFolder, recursive = TRUE)
  }
  
  tablesToExport <- c("dus_de_data_presence", "dus_de_detail", "dus_de_overview", "dus_drug_concept_xref")
  
  ParallelLogger::logInfo(paste0("Exporting ", databaseName, " results"))
  
  # Export the source info
  ParallelLogger::logInfo(("- source info"))
  .writeCSV(
    .exportSource(
      connection = connection,
      cdmDatabaseSchema = cdmDatabaseSchema,
      databaseName = databaseName
    ),
    tableName = "source",
    outputFolder = outputFolder,
    databaseId = databaseId
  )
  
  # Export the results
  for(i in 1:length(tablesToExport)) {
    tableName <- tablesToExport[i]
    ParallelLogger::logInfo(paste0("- ", tableName))
    .writeCSV(
      tableData  = .exportTable(
        connection = connection,
        resultsDatabaseSchema = resultsDatabaseSchema,
        targetTable = tableName
      ),
      tableName = tableName,
      outputFolder = outputFolder,
      databaseId = databaseId
    )
  }
  
  # Export the subset of concepts used in the analysis
  ParallelLogger::logInfo(("- concepts"))
  .writeCSV(
    .exportConceptSubset (
      connection = connection,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsDatabaseSchema = resultsDatabaseSchema
    ),
    tableName = "concept",
    outputFolder = outputFolder
  )
}

.exportSource <- function(connection,
                          cdmDatabaseSchema,
                          databaseName) {
  
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "get_vocab_version.sql",
      packageName = "DrugExposureCharacterization",
      dbms = attr(connection, "dbms"),
      cdm_database_schema = cdmDatabaseSchema
    )
  
  vocabInfo <- DatabaseConnector::querySql(connection, sql)
  return(cbind(SOURCE_NAME = databaseName, vocabInfo))
}

.exportConceptSubset <- function(connection,
                                 cdmDatabaseSchema,
                                 resultsDatabaseSchema) {
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "get_concept_subset_for_export.sql",
      packageName = "DrugExposureCharacterization",
      dbms = attr(connection, "dbms"),
      cdm_database_schema = cdmDatabaseSchema,
      results_database_schema = resultsDatabaseSchema
    )
  
  return(DatabaseConnector::querySql(connection, sql))
}

.exportTable <- function(connection,
                         resultsDatabaseSchema,
                         targetTable) {
  # Get results
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "select_all_from_table.sql",
      packageName = "DrugExposureCharacterization",
      dbms = attr(connection, "dbms"),
      results_database_schema = resultsDatabaseSchema,
      target_table = targetTable
    )
  
  return(DatabaseConnector::querySql(connection, sql))
}

.writeCSV <- function (tableData, tableName, outputFolder, databaseId = NULL) {
  exportFileName <- file.path(outputFolder, paste0(tableName, ".csv"))
  if (nrow(tableData) <= 0) {
    tableData[nrow(tableData)+1,] <- NA;
  }
  if (!is.null(databaseId)) {
    tableData <- cbind(SOURCE_ID = databaseId, tableData)
  }
  write.csv(tableData, exportFileName, row.names = FALSE)
}