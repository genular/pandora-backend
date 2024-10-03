# Load the necessary header files and configurations for the server environment
source("server/includes/header.R")

# Load the required libraries: plumber for API functionality and tidyverse for data manipulation
p_load(plumber)
p_load(tidyverse)

# Source helper functions for cron jobs and resampling tasks from the specified paths
source(paste0("cron/functions/helpers.R"))
source(paste0("cron/functions/resampleHelpers.R"))

# Dynamically load server-specific modules based on the SERVER_NAME environment variable.
# These modules include functionalities for correlation analysis, heatmaps, variable importance,
# statistical analysis, summary statistics, and distribution analysis.
source(paste0("server/", SERVER_NAME, "/correlation/main.R"))
source(paste0("server/", SERVER_NAME, "/heatmap/main.R"))
source(paste0("server/", SERVER_NAME, "/variableImportance/main.R"))
source(paste0("server/", SERVER_NAME, "/stats/main.R"))
source(paste0("server/", SERVER_NAME, "/summary/main.R"))
source(paste0("server/", SERVER_NAME, "/modelInterpretation/main.R"))
source(paste0("server/", SERVER_NAME, "/distribution/main.R"))

# Load modules for data editing and general utilities
source(paste0("server/", SERVER_NAME, "/editing/main.R"))
source(paste0("server/", SERVER_NAME, "/general/main.R"))

# Define a function to deploy the API with specified options, defaulting to localhost and port 8181.
# This function checks for the plumber library and sets up the API routes and hooks.
deployAPI <- function(pandora, options = list(host = "127.0.0.1", port = 8181)) {
    if (!requireNamespace("plumber", quietly = TRUE)) {
        stop('plumber (>= 1.0.0) is required for this function to work!')
    }
    cookie_name <- paste0("pandora_", SERVER_NAME)

    router <- plumber::plumber$new()
    router$registerHooks(session_cookie(pandoraConfig$secret, name = cookie_name, expiration = Sys.time() + (20 * 365 * 24 * 60 * 60)))

    # Register filters for logging, CORS, and authentication
    router$filter("logger", pandora$filter$logger)
    router$filter("cors", pandora$filter$cors)
    router$filter("authentication", pandora$filter$authentication)

    # Define API endpoints for default operations, plot status, statistical analyses, and various plot types
    # Each endpoint is associated with a handler function and, when applicable, a specific serializer
    router$handle("GET", "/", pandora$handle$default)
    router$handle("GET", "/plots/status/<hash>", pandora$handle$status, serializer = serializer_unboxed_json())
    router$handle("GET", "/plots/stats", pandora$handle$stats, serializer = serializer_unboxed_json())

    router$handle("GET", "/plots/correlation/render-options", pandora$handle$plots$correlation$renderOptions, serializer = serializer_unboxed_json())
    router$handle("GET", "/plots/correlation/render-plot", pandora$handle$plots$correlation$renderPlot, serializer = serializer_unboxed_json())

    router$handle("GET", "/plots/heatmap/render-plot", pandora$handle$plots$heatmap$renderPlot, serializer = serializer_unboxed_json())

    router$handle("GET", "/plots/variableImportance/render-plot", pandora$handle$plots$variableImportance$renderPlot, serializer = serializer_unboxed_json())

    router$handle("GET", "/plots/stats/multi-class", pandora$handle$plots$stats$multiClass, serializer = serializer_unboxed_json())
    router$handle("GET", "/plots/stats/two-class", pandora$handle$plots$stats$twoClass, serializer = serializer_unboxed_json())

    router$handle("GET", "/plots/summary/render-plot", pandora$handle$plots$summary$renderPlot, serializer = serializer_unboxed_json())

    ## Model Summary TAB
    router$handle("GET", "/plots/model-summary/render-plot/multi-class", pandora$handle$plots$modelsummary$renderPlot$multiClass, serializer = serializer_unboxed_json())

    ## Model Interpretation TAB
    router$handle("GET", "/plots/model-interpretation/render-plot", pandora$handle$plots$modelInterpretation$renderPlot, serializer = custom_json_serializer())

    router$handle("GET", "/plots/distribution/render-plot", pandora$handle$plots$distribution$renderPlot, serializer = serializer_unboxed_json())
    
    # Define additional editing and general utility endpoints
    router$handle("GET", "/plots/editing/correlation/render-options", pandora$handle$plots$editing$correlation$renderOptions, serializer = serializer_unboxed_json())
    router$handle("GET", "/plots/editing/correlation/render-plot", pandora$handle$plots$editing$correlation$renderPlot, serializer = serializer_unboxed_json())

    router$handle("GET", "/plots/editing/heatmap/render-plot", pandora$handle$plots$editing$heatmap$renderPlot, serializer = serializer_unboxed_json())

    router$handle("GET", "/plots/editing/pcaAnalysis/render-plot", pandora$handle$plots$editing$pcaAnalysis$renderPlot, serializer = serializer_unboxed_json())

    router$handle("GET", "/plots/editing/overview/getAvaliableColumns", pandora$handle$plots$editing$overview$getAvaliableColumns, serializer = serializer_unboxed_json())
    router$handle("GET", "/plots/editing/overview/render-plot", pandora$handle$plots$editing$overview$renderPlot, serializer = serializer_unboxed_json())

    router$handle("GET", "/plots/editing/tsne/render-plot", pandora$handle$plots$editing$tsne$renderPlot, serializer = serializer_unboxed_json())

    router$handle("GET", "/plots/general/download-saved-object", pandora$handle$plots$general$downloadSavedObject, serializer = serializer_content_type("application/octet-stream"))
    router$handle("GET", "/plots/general/get-temp-file-path", pandora$handle$plots$general$getObjectFilePath, serializer = serializer_unboxed_json())

    router$handle("GET", "/plots/editing/umap/render-plot", pandora$handle$plots$editing$umap$renderPlot, serializer = serializer_unboxed_json())

    # Start the router with the specified options
    router$run(host = options$proxy_host, port = as.numeric(options$proxy_port), debug = options$debug)
}

# Remove the uptime PID file if it exists to signify a fresh start
if (file.exists(UPTIME_PID)) {
    file.remove(UPTIME_PID)
}

# Record the start time of the Pandora service
pandora_started_at <- Sys.time()
write(as.POSIXct(format(pandora_started_at), tz = "GMT"), UPTIME_PID)

# Deploy the API using the configuration specified for the current server
deployAPI(pandora, pandoraConfig[[SERVER_NAME]]$server)
