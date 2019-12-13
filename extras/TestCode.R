# Details for connecting to the server:
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = Sys.getenv("DBMS"),
                                                                server = Sys.getenv("DB_SERVER"),
                                                                user = NULL,
                                                                password = NULL,
                                                                port = Sys.getenv("DB_PORT"))

# Basic SQL setup test
deOverview <- DrugUtilization::drugExposureOverview(connectionDetails, 
                                                    cdmDatabaseSchema = Sys.getenv("CDM_SCHEMA"),
                                                    resultsSchema = Sys.getenv("RESULTS_SCHEMA"),
                                                    drugConceptIds = c(939259,19060647))

