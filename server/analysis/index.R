# Load essential server configurations and the plumber library for API development
source("server/includes/header.R")
p_load(plumber)

# Dynamically source server-specific modules for additional analysis functionalities
source(paste0("server/", SERVER_NAME, "/other/main.R"))

# Define a function to deploy the API with customizable hosting options, defaulting to localhost:8181
# This function initializes the API, sets up session management, and configures middleware for logging, CORS, and authentication
deployAPI <- function(pandora, options = list(host = "127.0.0.1", port = 8181)) {
    # Ensure the plumber library is available, failing with an informative error if it is not
    if (!requireNamespace("plumber", quietly = TRUE)) {
        stop('plumber (>= 1.0.0) is required for this function to work!')
    }
    cookie_name <- paste0("pandora_", SERVER_NAME)
    
    router <- plumber::Plumber$new()
    # Register a session cookie for state management, using a secret from the configuration
    router$registerHooks(session_cookie(pandoraConfig$secret, name = cookie_name, expiration = Sys.time() + (20 * 365 * 24 * 60 * 60)))

    # Apply filters for request logging, cross-origin resource sharing, and request authentication
    router$filter("logger", pandora$filter$logger)
    router$filter("cors", pandora$filter$cors)
    router$filter("authentication", pandora$filter$authentication)

    # Default route to handle the base URL access
    router$handle("GET", "/", pandora$handle$default)

    # Endpoint to get a list of available machine learning packages, useful for dynamic UI elements or validation
    router$handle("GET", "/analysis/other/available-packages", pandora$handle$analysis$other$availablePackages, serializer = serializer_unboxed_json())

    # Endpoints for specific analysis features:
    # SAM (Significance Analysis of Microarrays) for high-dimensional data
    router$handle("GET", "/analysis/other/sam/render-options", pandora$handle$analysis$other$sam$renderOptions, serializer = serializer_unboxed_json())
    router$handle("GET", "/analysis/other/sam/render-plot", pandora$handle$analysis$other$sam$renderPlot, serializer = serializer_unboxed_json())

    # CatBoost predictive modeling, with options for configuring the model and submitting data for prediction
    router$handle("GET", "/analysis/other/predict/catboost/renderOptions", pandora$handle$analysis$other$predict$catboost$renderOptions, serializer = serializer_unboxed_json())
    router$handle("GET", "/analysis/other/predict/catboost/submit", pandora$handle$analysis$other$predict$catboost$submit, serializer = serializer_unboxed_json())

    # Start the API server with the specified options, including host, port, and debug settings
    router$run(host = options$proxy_host, port = as.numeric(options$proxy_port), debug = options$debug)
}

# Cleanup: remove the uptime PID file if it exists, signaling a restart or fresh deployment
if (file.exists(UPTIME_PID)) {
    invisible(file.remove(UPTIME_PID))
}
 
# Record the current time as the start time of the Pandora service, storing it in a designated PID file
pandora_started_at <- Sys.time()
write(as.POSIXct(format(pandora_started_at), tz = "GMT"), UPTIME_PID)

# Deploy the API using server-specific configurations
deployAPI(pandora, pandoraConfig[[SERVER_NAME]]$server)
