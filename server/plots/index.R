source("server/includes/header.R")
p_load(plumber)
p_load(tidyverse)

source(paste0("cron/functions/helpers.R"))

source(paste0("server/",SERVER_NAME,"/correlation/main.R"))
source(paste0("server/",SERVER_NAME,"/heatmap/main.R"))
source(paste0("server/",SERVER_NAME,"/variableImportance/main.R"))
source(paste0("server/",SERVER_NAME,"/stats/main.R"))
source(paste0("server/",SERVER_NAME,"/summary/main.R"))
source(paste0("server/",SERVER_NAME,"/distribution/main.R"))

source(paste0("server/",SERVER_NAME,"/editing/main.R"))
source(paste0("server/",SERVER_NAME,"/general/main.R"))

deployAPI<- function(pandora, options = list(host = "127.0.0.1", port = 8181)) {
    if(!requireNamespace("plumber", quietly = TRUE)) {
        stop('plumber (>= 1.0.0) is required for this function to work!')
    }
    cookie_name <- paste0("pandora_", SERVER_NAME)

    router <- plumber::plumber$new()
    router$registerHooks(session_cookie(pandoraConfig$secret, name=cookie_name, expiration=Sys.time() + (20 * 365 * 24 * 60 * 60)))

    router$filter("logger", pandora$filter$logger)
    router$filter("cors", pandora$filter$cors)
    router$filter("authentication", pandora$filter$authentication)

    router$handle("GET", "/", pandora$handle$default)
    router$handle("GET", "/plots/status/<hash>", pandora$handle$status, serializer=serializer_unboxed_json())
    router$handle("GET", "/plots/stats", pandora$handle$stats, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/correlation/render-options", pandora$handle$plots$correlation$renderOptions, serializer=serializer_unboxed_json())
    router$handle("GET", "/plots/correlation/render-plot", pandora$handle$plots$correlation$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/heatmap/render-plot", pandora$handle$plots$heatmap$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/variableImportance/render-plot", pandora$handle$plots$variableImportance$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/stats/multi-class", pandora$handle$plots$stats$multiClass, serializer=serializer_unboxed_json())
    router$handle("GET", "/plots/stats/two-class", pandora$handle$plots$stats$twoClass, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/summary/render-plot", pandora$handle$plots$summary$renderPlot, serializer=serializer_unboxed_json())
    router$handle("GET", "/plots/model-summary/render-plot", pandora$handle$plots$modelsummary$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/distribution/render-plot", pandora$handle$plots$distribution$renderPlot, serializer=serializer_unboxed_json())

    ### EDITING
    router$handle("GET", "/plots/editing/correlation/render-options", pandora$handle$plots$editing$correlation$renderOptions, serializer=serializer_unboxed_json())
    router$handle("GET", "/plots/editing/correlation/render-plot", pandora$handle$plots$editing$correlation$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/editing/heatmap/render-plot", pandora$handle$plots$editing$heatmap$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/editing/pcaAnalysis/render-plot", pandora$handle$plots$editing$pcaAnalysis$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/editing/overview/getAvaliableColumns", pandora$handle$plots$editing$overview$getAvaliableColumns, serializer=serializer_unboxed_json())
    router$handle("GET", "/plots/editing/overview/render-plot", pandora$handle$plots$editing$overview$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/editing/tsne/render-plot", pandora$handle$plots$editing$tsne$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/general/download-saved-object", pandora$handle$plots$general$downloadSavedObject, serializer=serializer_content_type("application/octet-stream"))

    router$handle("GET", "/plots/editing/umap/render-plot", pandora$handle$plots$editing$umap$renderPlot, serializer=serializer_unboxed_json())
    
    router$run(host = options$proxy_host, port = as.numeric(options$proxy_port), debug = options$debug)
}

if(file.exists(UPTIME_PID)){
    file.remove(UPTIME_PID)
}
 
pandora_started_at <- Sys.time()
write(as.POSIXct(format(pandora_started_at), tz="GMT"), UPTIME_PID)

deployAPI(pandora, pandoraConfig[[SERVER_NAME]]$server)
