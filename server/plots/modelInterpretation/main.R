p_load(plotmo)
p_load(iml)


source(paste0("server/",SERVER_NAME,"/modelInterpretation/functions/index.R"))

## POST & GET Declarations
simon$handle$plots$modelInterpretation = list()
source(paste0("server/",SERVER_NAME,"/modelInterpretation/api/index.R"))
