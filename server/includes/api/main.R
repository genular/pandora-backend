#' Main Endpoint
#' @serializer boxedJSON
#' @get /
pandora$handle$default <- expression(
    function(){
      return(Sys.time())
    }
)

#' Status Details Endpoint
#' @serializer unboxedJSON
#' @get /stats
pandora$handle$stats <- expression(
    function(req, res){
        status <- "success"

        current_time <- as.POSIXct(format(Sys.time()), tz="GMT")

        pandora_started_at <- as.numeric(scan(UPTIME_PID, quiet = TRUE))
        pandora_started_at <- as.POSIXct(pandora_started_at, origin="1970-01-01", tz="GMT")

        total_time <- difftime(current_time, pandora_started_at,  units = c("secs"))
        total_time_ms <- ceiling((as.numeric(total_time, units="secs") * 1000))

        data_count <- db.getTotalCount(c("users", "models", "models_performance"))
        
        return(list(
            status = status,
            data = list(
                users = data_count$users,
                models = data_count$models,
                features = data_count$models_performance,
                uptime = (total_time_ms / (1000*60*60*24))
            )
        ))
    }
)

#' Status Endpoint
#' @serializer unboxedJSON
#' @get /status/<hash>
pandora$handle$status <- expression(
    function(hash, req){
        status <- "error"

        cpu_cores <- NULL
        ram_total <- NULL
        ram_free <- NULL

        if(nchar(hash) == 32){
            status <- "success"
            cpu_cores <- parallel::detectCores(all.tests = FALSE, logical = TRUE)
            ram_total <- as.numeric(system("awk '/MemTotal/ {print $2}' /proc/meminfo", intern=TRUE))
            ram_free <- as.numeric(system("awk '/MemFree/ {print $2}' /proc/meminfo", intern=TRUE))
        }

        i <- 1
        server_details <- list() 

        for(server_name in SERVER_TYPES){
            server_details[[i]] <- list(type = server_name, host = pandoraConfig[[server_name]]$server$host, port = pandoraConfig[[server_name]]$server$port)
            i <- i + 1
        }

        return(list(
            status = status,
            servers = server_details,
            system = list(            
                cpu_cores = cpu_cores,
                ram_total = ram_total,
                ram_free = ram_free)
            )
        )
    }
)
