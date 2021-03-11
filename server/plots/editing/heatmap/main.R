require(corrplot)
source(paste0("server/",SERVER_NAME,"/editing/heatmap/functions/heatmap.R"))
## POST & GET Declarations
simon$handle$plots$editing$heatmap = list()
source(paste0("server/",SERVER_NAME,"/editing/heatmap/api/index.R"))
