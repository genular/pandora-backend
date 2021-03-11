p_load("corrplot")
p_load("hablar")

source(paste0("server/",SERVER_NAME,"/editing/pcaAnalysis/functions/index.R"))

## POST & GET Declarations
simon$handle$plots$editing$pcaAnalysis = list()
source(paste0("server/",SERVER_NAME,"/editing/pcaAnalysis/api/index.R"))
