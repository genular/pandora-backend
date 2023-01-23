p_load("corrplot")
## Load shared heatmap functions file
source(paste0("server/",SERVER_NAME,"/functions/heatmap.R"))
## POST & GET Declarations
pandora$handle$plots$editing$heatmap = list()
source(paste0("server/",SERVER_NAME,"/editing/heatmap/api/index.R"))
