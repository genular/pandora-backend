p_load("corrplot")

source(paste0("server/",SERVER_NAME,"/functions/correlation.R"))
source(paste0("server/",SERVER_NAME,"/correlation/functions/index.R"))

## POST & GET Declarations
simon$handle$plots$correlation = list()
source(paste0("server/",SERVER_NAME,"/correlation/api/index.R"))
