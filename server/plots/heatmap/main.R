require(corrplot)
source(paste0("server/",SERVER_NAME,"/heatmap/functions/heatmap.R"))
## POST & GET Declarations
simon$handle$plots$heatmap = list()
source(paste0("server/",SERVER_NAME,"/heatmap/api/index.R"))
