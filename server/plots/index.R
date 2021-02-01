source("server/includes/header.R")
p_load(plumber)

source(paste0("server/",SERVER_NAME,"/correlation/main.R"))
source(paste0("server/",SERVER_NAME,"/heatmap/main.R"))
source(paste0("server/",SERVER_NAME,"/variableImportance/main.R"))
source(paste0("server/",SERVER_NAME,"/stats/main.R"))
source(paste0("server/",SERVER_NAME,"/summary/main.R"))
source(paste0("server/",SERVER_NAME,"/distribution/main.R"))

deployAPI<- function(simon, options = list(host = "127.0.0.1", port = 8181)) {
    if(!requireNamespace("plumber", quietly = TRUE)) {
        stop('plumber (>= 1.0.0) is required for this function to work!')
    }
    cookie_name <- paste0("simon_", SERVER_NAME)

    router <- plumber::plumber$new()
    router$registerHooks(session_cookie(simonConfig$secret, name=cookie_name, expiration=Sys.time() + (20 * 365 * 24 * 60 * 60)))

    router$filter("logger", simon$filter$logger)
    router$filter("cors", simon$filter$cors)
    router$filter("authentication", simon$filter$authentication)

    router$handle("GET", "/", simon$handle$default)
    router$handle("GET", "/plots/status/<hash>", simon$handle$status, serializer=serializer_unboxed_json())
    router$handle("GET", "/plots/stats", simon$handle$stats, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/correlation/render-options", simon$handle$plots$correlation$renderOptions, serializer=serializer_unboxed_json())
    router$handle("GET", "/plots/correlation/render-plot", simon$handle$plots$correlation$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/heatmap/render-plot", simon$handle$plots$heatmap$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/variableImportance/render-plot", simon$handle$plots$variableImportance$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/stats/multi-class", simon$handle$plots$stats$multiClass, serializer=serializer_unboxed_json())
    router$handle("GET", "/plots/stats/two-class", simon$handle$plots$stats$twoClass, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/summary/render-plot", simon$handle$plots$summary$renderPlot, serializer=serializer_unboxed_json())
    router$handle("GET", "/plots/model-summary/render-plot", simon$handle$plots$modelsummary$renderPlot, serializer=serializer_unboxed_json())

    router$handle("GET", "/plots/distribution/render-plot", simon$handle$plots$distribution$renderPlot, serializer=serializer_unboxed_json())
    
    router$run(host = options$proxy_host, port = as.numeric(options$proxy_port), debug = options$debug)
}

if(file.exists(UPTIME_PID)){
    file.remove(UPTIME_PID)
}
 
simon_started_at <- Sys.time()
write(as.POSIXct(format(simon_started_at), tz="GMT"), UPTIME_PID)

deployAPI(simon, simonConfig[[SERVER_NAME]]$server)
