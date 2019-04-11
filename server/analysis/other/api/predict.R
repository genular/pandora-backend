#' @get /analysis/other/predict/catboost/renderOptions
simon$handle$analysis$other$predict$catboost$renderOptions <- expression(
    function(){
        data <- list()

        data$kFolds <-list(value= 5, min= 1, max= 10, step= 1)
        data$cvRepeats <-list(value= 3, min= 1, max= 10, step= 1)
        data$tuneLength <-list(value= 5, min= 1, max= 10, step= 1)
        data$random_seed <- sample(1000:10000, 1)

        return(list(
            status = "success",
            message = data
        ))
    }
)


#' @get /analysis/other/predict/catboost/submit
simon$handle$analysis$other$predict$catboost$submit <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        resampleID <- 0
        if("resampleID" %in% names(args)){
            resampleID <- as.numeric(args$resampleID)
        }

        settings <- NULL
        if("settings" %in% names(args)){
            settings <- jsonlite::fromJSON(RCurl::base64Decode(URLdecode(args$settings)))
        }


        package_installed <- TRUE
        if (!require("catboost", character.only=T, quietly=T)) {
            package_installed <- FALSE
        }
        if(package_installed == FALSE){
            return(list(
                    status = package_installed,
                    message = "catboost package missing")
            )
        }

        ## Get JOB and his Info from database
        resampleDetails <- db.apps.getFeatureSetData(resampleID)

        dataset <- resampleDetails[[1]]
        data = list(training = "",testing = "")

        filePathTraining <- downloadDataset(dataset$remotePathTrain)
        filePathTesting <- downloadDataset(dataset$remotePathTest)

        ## Download dataset if not downloaded already
        data$training <- data.table::fread(filePathTraining, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)
        data$testing <- data.table::fread(filePathTesting, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)

        ## Coerce data to a standard data.frame
        data$training <- base::as.data.frame(data$training, stringsAsFactors = TRUE)
        data$testing <- base::as.data.frame(data$testing, stringsAsFactors = TRUE)

        ## Remove all columns expect selected features and outcome
        data$training <- data$training[, base::names(data$training) %in% c(dataset$features$remapped, dataset$outcome$remapped)]
        data$testing <- data$testing[, base::names(data$testing) %in% c(dataset$features$remapped, dataset$outcome$remapped)]

        modelData = list(training = data$training, testing = data$testing)


        cat(paste0("===> INFO: Setting factors for datasets on: ",dataset$outcome$remapped," column. \n"))

        ## Establish factors for outcome column
        ## Specify library ("base") since some other libraries overwrite as.factor functions like h2o
        modelData$training[[dataset$outcome$remapped]] <- base::as.factor(modelData$training[[dataset$outcome$remapped]])
        modelData$training[[dataset$outcome$remapped]] <- base::factor(
            modelData$training[[dataset$outcome$remapped]], levels = base::levels(modelData$training[[dataset$outcome$remapped]])
        )
        modelData$testing[[dataset$outcome$remapped]] <- base::as.factor(modelData$testing[[dataset$outcome$remapped]])
        modelData$testing[[dataset$outcome$remapped]] <- base::factor(
            modelData$testing[[dataset$outcome$remapped]], levels = base::levels(modelData$testing[[dataset$outcome$remapped]])
        )

        JOB_DIR <- initilizeDatasetDirectory(dataset)
        
        model_details = list(
            internal_id = "catboost.caret",
            interface = "matrix",
            prob = TRUE,
            trControl = list(method = "boot", number = 3, repeats = 3, allowParallel = FALSE),
            process_timeout = 300,
            ## https://github.com/catboost/catboost/blob/master/catboost/R-package/R/catboost.R
            model_specific_args = list(logging_level = 'Info', train_dir = JOB_DIR, save_snapshot = FALSE, allow_writing_files = FALSE, thread_count = 1)
        )

        trainModel <- caretTrainModel(modelData$training, model_details, "classification", dataset$outcome$remapped, NULL, dataset$resampleID, JOB_DIR)
        
        ## Define results variables
        results_auc <- NULL
        results_confusionMatrix <- NULL
        results_varImportance <- NULL
        prediction <- NULL

        print(trainModel)

        return(list(
                training_model = NULL,
                prediction = NULL,
                importance = NULL,
                roc = NULL,
                auc = NULL)
        )
    }
)
