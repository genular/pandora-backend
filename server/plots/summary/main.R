require(corrplot);
require(plotROC)

source(paste0("server/",SERVER_NAME,"/summary/functions/index.R"))
## POST & GET Declarations
simon$handle$plots$summary = list()
source(paste0("server/",SERVER_NAME,"/summary/api/index.R"))
source(paste0("server/",SERVER_NAME,"/summary/api/model-summary.R"))
