p_load("corrplot")
## Load shared heatmap functions file
source(paste0("server/",SERVER_NAME,"/functions/heatmap.R"))
## POST & GET Declarations
simon$handle$plots$heatmap = list()
source(paste0("server/",SERVER_NAME,"/heatmap/api/index.R"))
