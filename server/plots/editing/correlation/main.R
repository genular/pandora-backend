p_load("corrplot")

source(paste0("server/",SERVER_NAME,"/editing/correlation/functions/index.R"))

## POST & GET Declarations
simon$handle$plots$editing$correlation = list()
source(paste0("server/",SERVER_NAME,"/editing/correlation/api/index.R"))
