p_load("corrplot")
p_load("hablar")

source(paste0("server/",SERVER_NAME,"/functions/correlation.R"))
source(paste0("server/",SERVER_NAME,"/editing/correlation/functions/index.R"))

## POST & GET Declarations
pandora$handle$plots$editing$correlation = list()
source(paste0("server/",SERVER_NAME,"/editing/correlation/api/index.R"))
