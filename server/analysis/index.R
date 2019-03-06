library(plumber)
source("server/includes/header.R")

source(paste0("server/",SERVER_NAME,"/other/main.R"))

deployAPI<- function(simon, options = list(host = "127.0.0.1", port = 8181)) {
    if(!requireNamespace("plumber", quietly = TRUE)) {
        stop('plumber (>= 0.3.0) is required for this function to work!')
    }
    cookie_name <- paste0("simon_", SERVER_NAME)
    
    router <- plumber::plumber$new()
    router$registerHooks(sessionCookie(simonConfig$secret, name=cookie_name, path="/", expiration=Sys.time() + (20 * 365 * 24 * 60 * 60)))

    router$filter("logger", simon$filter$logger)
    router$filter("cors", simon$filter$cors)
    router$filter("authentication", simon$filter$authentication)

    router$handle("GET", "/", simon$handle$default)

    ## Get list of installed ML packages
    router$handle("GET", "/analysis/other/available-packages", simon$handle$analysis$other$availablePackages, serializer=serializer_unboxed_json())

    ## Use on front-end in exploration analysis
    ## SAM
    router$handle("GET", "/analysis/other/sam/render-options", simon$handle$analysis$other$sam$renderOptions, serializer=serializer_unboxed_json())
    router$handle("GET", "/analysis/other/sam/render-plot", simon$handle$analysis$other$sam$renderPlot, serializer=serializer_unboxed_json())

    ## CATBOOST
    router$handle("GET", "/analysis/other/predict/catboost/renderOptions", simon$handle$analysis$other$predict$catboost$renderOptions, serializer=serializer_unboxed_json())
    router$handle("GET", "/analysis/other/predict/catboost/submit", simon$handle$analysis$other$predict$catboost$submit, serializer=serializer_unboxed_json())

    router$run(host = options$proxy_host, port = as.numeric(options$proxy_port), debug = options$debug)
}

if(file.exists(UPTIME_PID)){
    file.remove(UPTIME_PID)
}
 
simon_started_at <- Sys.time()
write(as.POSIXct(format(simon_started_at), tz="GMT"), UPTIME_PID)

deployAPI(simon, simonConfig[[SERVER_NAME]]$server)
