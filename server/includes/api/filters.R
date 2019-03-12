#* @filter logger
simon$filter$logger <- function(req){
    cat(as.character(Sys.time()), "-",  req$REQUEST_METHOD, req$PATH_INFO, "-",  req$HTTP_USER_AGENT, "@", req$REMOTE_ADDR, "\n")
    plumber::forward()
}

#* @filter cors
simon$filter$cors <- function(req, res){
    res$setHeader("Access-Control-Allow-Origin", simonConfig$frontend$server$url)
    res$setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, PATCH, OPTIONS, HEAD")
    res$setHeader("Access-Control-Allow-Headers", "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Origin,Accept,X-Token")
    
    ##  If request is not OPTIONS forward otherwise stop the app, and sends the response
    if(req$REQUEST_METHOD != "OPTIONS"){
        return (plumber::forward())
    }else{
        return (res)
    }
}

#* @filter authentication
simon$filter$authentication <- function(req, res){
    route_whitelist <- c('/analysis/other/available-packages')
    current_route <- req$PATH_INFO

    auth_token <- NULL

    if("HTTP_X_TOKEN" %in% names(req)){
        auth_token <- req$HTTP_X_TOKEN
        results <- db.checkUserAuthToken(auth_token)
    }

    if(!is.null(auth_token) && nrow(results) > 0){
        if(nrow(results) > 0){
            req$uid <- results$uid
            req$sid <- results$id
            req$salt <- results$salt
            plumber::forward()
        }
    }else{
        if(TRUE %in% startsWith(current_route, route_whitelist)){
            plumber::forward()
        }else{
            res$status <- 401 # Unauthorized
            return(list(status = "error", description="Authentication required"))
        }
    }
}

