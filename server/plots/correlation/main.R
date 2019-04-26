require(corrplot)

source(paste0("server/",SERVER_NAME,"/correlation/functions/index.R"))

## POST & GET Declarations
simon$handle$plots$correlation = list()
source(paste0("server/",SERVER_NAME,"/correlation/api/index.R"))
