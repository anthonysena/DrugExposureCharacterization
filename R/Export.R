#' @export
exportResultsToCSV <- function(connectionDetails,
                               cdmDatabaseSchema,
                               oracleTempSchema = cdmDatabaseSchema,
                               resultsSchema,
                               outputFolder,
                               sourceId,
                               sourceName) {
  if (is.null(sourceId)) {
    stop("You must provide a source ID to export results.")
  }
  if (is.null(sourceName)) {
    stop("You must provide a name for the source.")
  }
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  
  exportFolder <- file.path(outputFolder, "export", paste0(sourceId, "_", sourceName))
  if (!file.exists(exportFolder)) {
    dir.create(exportFolder, recursive = TRUE)
  }
  
  tablesToExport <- c("dus_de_data_presence", "dus_de_detail", "dus_de_overview", "dus_drug_concept_xref")
  
  ParallelLogger::logInfo(paste0("Exporting ", sourceName, " results"))
  
  # Export the source info
  ParallelLogger::logInfo(("- source info"))
  .writeCSV(
    .exportSource(
      connection = connection,
      cdmDatabaseSchema = cdmDatabaseSchema,
      sourceName = sourceName
    ),
    tableName = "source",
    exportFolder = exportFolder,
    sourceId = sourceId
  )
  
  # Export the results
  for(i in 1:length(tablesToExport)) {
    tableName <- tablesToExport[i]
    ParallelLogger::logInfo(paste0("- ", tableName))
    .writeCSV(
      tableData  = .exportTable(
        connection = connection,
        resultsSchema = resultsSchema,
        targetTable = tableName
      ),
      tableName = tableName,
      exportFolder = exportFolder,
      sourceId = sourceId
    )
  }
  
  # Export the subset of concepts used in the analysis
  ParallelLogger::logInfo(("- concepts"))
  .writeCSV(
    .exportConceptSubset (
      connection = connection,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsSchema = resultsSchema
    ),
    tableName = "concept",
    exportFolder = exportFolder
  )
}

.exportSource <- function(connection,
                          cdmDatabaseSchema,
                          sourceName) {
  
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "get_vocab_version.sql",
      packageName = "DrugUtilization",
      dbms = attr(connection, "dbms"),
      cdmDatabaseSchema = cdmDatabaseSchema
    )
  
  vocabInfo <- DatabaseConnector::querySql(connection, sql)
  return(cbind(SOURCE_NAME = sourceName, vocabInfo))
}

.exportConceptSubset <- function(connection,
                                 cdmDatabaseSchema,
                                 resultsSchema) {
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "get_concept_subset_for_export.sql",
      packageName = "DrugUtilization",
      dbms = attr(connection, "dbms"),
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsSchema = resultsSchema
    )
  
  return(DatabaseConnector::querySql(connection, sql))
}

.exportTable <- function(connection,
                         resultsSchema,
                         targetTable) {
  # Get results
  sql <-
    SqlRender::loadRenderTranslateSql(
      sqlFilename = "select_all_from_table.sql",
      packageName = "DrugUtilization",
      dbms = attr(connection, "dbms"),
      resultsSchema = resultsSchema,
      targetTable = targetTable
    )
  
  return(DatabaseConnector::querySql(connection, sql))
}

.writeCSV <- function (tableData, tableName, exportFolder, sourceId = NULL) {
  if (!is.null(sourceId)) {
    tableData <- cbind(SOURCE_ID = sourceId, tableData)
  }
  exportFileName <- file.path(exportFolder, paste0(tableName, ".csv"))
  if (nrow(tableData) > 0) {
    # write.table(
    #   cbind(sourceId, tableData),
    #   file = exportFileName,
    #   sep = ",",
    #   col.names = F,
    #   row.names = F,
    #   append = T
    # )
    write.csv(tableData, exportFileName, row.names = FALSE)
  }
}