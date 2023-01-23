## POST & GET Declarations
pandora$handle$analysis$other = list(sam = list(), predict = list(catboost=list()))
source(paste0("server/",SERVER_NAME,"/other/api/index.R"))
source(paste0("server/",SERVER_NAME,"/other/api/sam.R"))

## Include helpers to make predictions
source("cron/functions/caretPredict.R")
source("cron/functions/postProcessModel.R")
source("cron/functions/preProcessDataset.R")

source(paste0("server/",SERVER_NAME,"/other/api/predict.R"))
