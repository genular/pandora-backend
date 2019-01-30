## POST & GET Declarations
simon$handle$analysis$other = list(sam = list(), predict = list(catboost=list()))
source(paste0("server/",SERVER_NAME,"/other/api/index.R"))
source(paste0("server/",SERVER_NAME,"/other/api/sam.R"))
source(paste0("server/",SERVER_NAME,"/other/api/predict.R"))
