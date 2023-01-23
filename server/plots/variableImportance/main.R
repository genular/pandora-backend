require(ggplot2);
## POST & GET Declarations
pandora$handle$plots$variableImportance = list()
source(paste0("server/",SERVER_NAME,"/variableImportance/api/index.R"))
