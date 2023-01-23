#' @get /apps/pandora/dataset/multiClass
pandora$handle$plots$stats$multiClass <- expression(
    function(req, res, ...){
        status <- "success"
        args <- as.list(match.call())

        resampleID <- NULL 
        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
        }
        
        column_name <- NULL 
        if("column_name" %in% names(args)){
            column_name <- as.numeric(args$column_name)
        }

        return(list(
            status = status,
            data = resampleID
        ))
    }
)

#' @get /apps/pandora/dataset/twoClass
pandora$handle$plots$stats$twoClass <- expression(
    function(req, res, ...){
        status <- "success"
        data <- list(
            categories = c("Training", "Testing"),
            series = list()
        )

        args <- as.list(match.call())

        resampleID <- NULL
        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
        }
        column_name <- NULL
        if("column_name" %in% names(args)){
            column_name <- args$column_name
        }

        ## 1st - Get JOB and his Info from database
        current_job <- db.apps.getFeatureSetData(resampleID)
        ROOT_DIR <- file.path(DATA_PATH, current_job$job_id)

        filename <- paste0(ROOT_DIR,"/data/combined.feather")
        dataset <- read_feather(filename)
        series <- unique(dataset[[column_name]])

        data$types <- series
        remove(dataset)
        
        for (serie in series) {
            ## series name sould always be String to fix some strange Integer issues
            serie_name <- paste0("Data: ", serie)

            filename <- paste0(ROOT_DIR,"/data/training.feather")
            if(!file.exists(filename)){
                next()
            }
            dataset_training <- read_feather(filename)

            filename <- paste0(ROOT_DIR,"/data/testing.feather")
            if(!file.exists(filename)){
                next()
            }
            dataset_testing <- read_feather(filename)

            specific_data_testing <- dataset_testing[dataset_testing[[column_name]] == serie,]
            specific_data_training <- dataset_training[dataset_training[[column_name]] == serie,]

            count_training <- nrow(specific_data_training)
            count_testing <- nrow(specific_data_testing)
            count_total <- (count_training + count_testing)
            #median_value <- median(specific_data_testing[, column_name])

            data$series[[serie_name]] = list(
                name = serie,
                data = list(
                    training = count_training,
                    testing = count_testing,
                    total = count_total
                    #median = median_value
                )
            )
        }

        return(list(
            status = status,
            data = data
        ))
    }
)
