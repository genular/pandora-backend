p_load("corrplot")
p_load("hablar")

source(paste0("server/",SERVER_NAME,"/editing/correlation/functions/index.R"))

## POST & GET Declarations
simon$handle$plots$editing$correlation = list()
source(paste0("server/",SERVER_NAME,"/editing/correlation/api/index.R"))
