p_load("mclust")
p_load("fpc")
p_load("FNN")
p_load("Rtsne")

source(paste0("server/",SERVER_NAME,"/editing/tsne/functions/index.R"))

## POST & GET Declarations
simon$handle$plots$editing$tsne = list()
source(paste0("server/",SERVER_NAME,"/editing/tsne/api/index.R"))
