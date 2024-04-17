require(corrplot)
p_load(plotROC)

p_load(gridExtra)
p_load(scales)
p_load(pROC)


source(paste0("server/",SERVER_NAME,"/summary/functions/index.R"))
source(paste0("server/",SERVER_NAME,"/summary/functions/plots.R"))

## Multi-class ROCs
source(paste0("server/",SERVER_NAME,"/summary/functions/roc-testing.R"))
source(paste0("server/",SERVER_NAME,"/summary/functions/roc-training.R"))


## POST & GET Declarations
pandora$handle$plots$summary = list()
source(paste0("server/",SERVER_NAME,"/summary/api/training-summary-index.R"))

source(paste0("server/",SERVER_NAME,"/summary/api/model-summary-multi-class.R"))
