p_load("corrplot")
p_load("hablar")
p_load("FactoMineR")
p_load("factoextra")


source(paste0("server/",SERVER_NAME,"/editing/pcaAnalysis/functions/ffviz_plots.R"))
source(paste0("server/",SERVER_NAME,"/editing/pcaAnalysis/functions/index.R"))

## POST & GET Declarations
pandora$handle$plots$editing$pcaAnalysis = list()
source(paste0("server/",SERVER_NAME,"/editing/pcaAnalysis/api/index.R"))
