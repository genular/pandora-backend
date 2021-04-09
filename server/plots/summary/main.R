require(corrplot)
p_load(plotROC)

p_load(gridExtra)
p_load(scales)
p_load(pROC)


source(paste0("server/",SERVER_NAME,"/summary/functions/index.R"))
source(paste0("server/",SERVER_NAME,"/summary/functions/plots.R"))
## POST & GET Declarations
simon$handle$plots$summary = list()
source(paste0("server/",SERVER_NAME,"/summary/api/index.R"))
source(paste0("server/",SERVER_NAME,"/summary/api/model-summary.R"))
