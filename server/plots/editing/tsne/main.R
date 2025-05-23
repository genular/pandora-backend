p_load("ggplot2")
p_load("dplyr")
p_load("mclust")
p_load("fpc")
p_load("FNN")
p_load("Rtsne")
p_load("corrplot")
p_load("dbscan")
p_load("cluster")
p_load("viridis")

# Load reticulate for interfacing with Python
p_load("reticulate")

## Load shared heatmap functions file
source(paste0("server/",SERVER_NAME,"/functions/heatmap.R"))
source(paste0("server/",SERVER_NAME,"/editing/tsne/functions/index.R"))

## POST & GET Declarations
pandora$handle$plots$editing$tsne = list()
source(paste0("server/",SERVER_NAME,"/editing/tsne/api/index.R"))
