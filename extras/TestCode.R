# Get settings from .Renviron
user <- if(Sys.getenv("DB_USER")=="") NULL else Sys.getenv("DB_USER")
password <- if(Sys.getenv("DB_PASSWORD")=="") NULL else Sys.getenv("DB_PASSWORD")
cdmDatabaseSchema <- Sys.getenv("CDM_SCHEMA")
resultsSchema <- Sys.getenv("RESULTS_SCHEMA")

# Details for connecting to the server:
connectionDetails <-
  DatabaseConnector::createConnectionDetails(
    dbms = Sys.getenv("DBMS"),
    server = Sys.getenv("DB_SERVER"),
    user = user,
    password = password,
    port = Sys.getenv("DB_PORT")
  )

# ATC => RXNORM
# cimetidine (A02BA01) + cimetidine, combinations (A02BA51) => 997276
# ranitidine (A02BA02) + ranitidine bismuth citrate (A02BA07) => 	961047
# famotidine (A02BA03) + famotidine, combinations (A02BA53) => 953076
# nizatidine (A02BA04) => 950696
# roxatidine (A02BA06) => 19011685
# lafutidine (A02BA08) => 43009003

drugConceptsOfInterest <- c(997276, 961047, 953076, 950696, 19011685, 43009003, 40007176)

# Concept Utilities --------------------------
deConceptList = DrugUtilization::getConcepts(
  connectionDetails, 
  cdmDatabaseSchema = cdmDatabaseSchema, 
  conceptIds = drugConceptsOfInterest
)

onlyIngredients <- DrugUtilization::isConceptListOfIngredients(deConceptList, drugConceptsOfInterest)

# Vocabulary Exploration --------------------------
DrugUtilization::createDrugVocabExploration(
    connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsSchema = resultsSchema,
    includeDescendants = TRUE,
    drugConceptIds = drugConceptsOfInterest,
    debug = F,
    debugSqlFile = "vocab.dsql"
)

# Get drug exposure source code map
deSourceCodeMap <-
  DrugUtilization::getDrugExposureSourceMap (
    connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsSchema = resultsSchema
  )

# # Drug Exposure Overview --------------
# 
# # Create exposure overview
# DrugUtilization::createDrugExposureOverview(
#   connectionDetails,
#   cdmDatabaseSchema = cdmDatabaseSchema,
#   resultsSchema = resultsSchema,
#   includeDescendants = TRUE,
#   drugConceptIds = drugConceptsOfInterest #c(939259, 19060647) -- COPD
# )
# 
# # Get exposure overview
# deOverview <-
#   DrugUtilization::getDrugExposureOverview(
#     connectionDetails,
#     cdmDatabaseSchema = cdmDatabaseSchema,
#     resultsSchema = resultsSchema
#   )
# 
# # Get distributions
# deDist <-
#   DrugUtilization::getDrugExposureDistribution(
#     connectionDetails,
#     cdmDatabaseSchema = cdmDatabaseSchema,
#     resultsSchema = resultsSchema
#   )
# 
# # Get data presence
# dePresence <-
#   DrugUtilization::getDrugDataPresence(
#     connectionDetails,
#     cdmDatabaseSchema = cdmDatabaseSchema,
#     resultsSchema = resultsSchema
#   )
