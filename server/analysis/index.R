source("server/includes/header.R")
p_load(plumber)

source(paste0("server/",SERVER_NAME,"/other/main.R"))

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

    ## Get list of installed ML packages
    router$handle("GET", "/analysis/other/available-packages", pandora$handle$analysis$other$availablePackages, serializer=serializer_unboxed_json())

    ## Use on front-end in exploration analysis
    ## SAM
    router$handle("GET", "/analysis/other/sam/render-options", pandora$handle$analysis$other$sam$renderOptions, serializer=serializer_unboxed_json())
    router$handle("GET", "/analysis/other/sam/render-plot", pandora$handle$analysis$other$sam$renderPlot, serializer=serializer_unboxed_json())

    ## CATBOOST
    router$handle("GET", "/analysis/other/predict/catboost/renderOptions", pandora$handle$analysis$other$predict$catboost$renderOptions, serializer=serializer_unboxed_json())
    router$handle("GET", "/analysis/other/predict/catboost/submit", pandora$handle$analysis$other$predict$catboost$submit, serializer=serializer_unboxed_json())

    router$run(host = options$proxy_host, port = as.numeric(options$proxy_port), debug = options$debug)
}

if(file.exists(UPTIME_PID)){
    file.remove(UPTIME_PID)
}
 
pandora_started_at <- Sys.time()
write(as.POSIXct(format(pandora_started_at), tz="GMT"), UPTIME_PID)

deployAPI(pandora, pandoraConfig[[SERVER_NAME]]$server)
