p_load(ggplot2)

p_load(pdp)
p_load(lime)
p_load(import)
p_load(iml)


source(paste0("server/",SERVER_NAME,"/modelInterpretation/functions/index.R"))

## POST & GET Declarations
pandora$handle$plots$modelInterpretation = list()
source(paste0("server/",SERVER_NAME,"/modelInterpretation/api/index.R"))
