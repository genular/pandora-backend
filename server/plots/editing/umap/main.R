p_load("uwot")

source(paste0("server/",SERVER_NAME,"/editing/umap/functions/index.R"))

## POST & GET Declarations
pandora$handle$plots$editing$umap = list()
source(paste0("server/",SERVER_NAME,"/editing/umap/api/index.R"))
