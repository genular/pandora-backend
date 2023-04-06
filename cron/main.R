#!/usr/bin/Rscript --vanilla

## Warning: This CRON should be run called in following way:
## * * * * * /usr/bin/flock -n /tmp/pandora_backend.pid /path/to/cron.R

## Set ROOT working directory since CRON is maybe not called from root
raw_args <- commandArgs(trailingOnly=FALSE)
working_dir <- NULL
for (arg in raw_args) {
   if(base::startsWith(arg, "--file=") == TRUE){
        cron_file <- gsub("^.*\\=","",arg)
        ## Check if its a absolute path or a relative path
        if(base::startsWith(cron_file, "/") == TRUE){
            cron_dir <- base::dirname(cron_file)
        }else{
            pre_dir <- system("pwd", TRUE)
            post_dir <- base::dirname(cron_file)
            cron_dir <- file.path(pre_dir, post_dir)
        }
        cron_dir <- base::normalizePath(cron_dir)
        # This is now path to CRON subdirectory
        # lets move it one directory up
        if(dir.exists(cron_dir)){
            work_dir <- base::normalizePath(paste0(cron_dir, "/../"))
            if(dir.exists(work_dir)){
                working_dir <- work_dir
            }
        }
   }
}

if (!is.null(working_dir)){
    cat(paste0("======> INFO: Initializing CRON. Working directory: ",working_dir," <======\r\n"))
    setwd(working_dir)
}

source("server/includes/header.R")

# for parallel CPU processing
p_load(doMC)
p_load(caret)
p_load(ggplot2)
p_load(dplyr)

source("cron/functions/database.R")
source("cron/functions/helpers.R")
source("cron/functions/resampleHelpers.R")
source("cron/functions/caretPredict.R")
source("cron/functions/postProcessModel.R")
source("cron/functions/preProcessDataset.R")

maximum_memory <- getUseableFreeMemory(basePoint = 1000, systemReserved = 2000000)
## options(warn=0)
options(max.print=1000000)
options(stringsAsFactors=FALSE)
##  Java - maximum size of memory allocation pool
options(java.parameters=paste0("-Xmx",maximum_memory,"M"))

# Set global CRON execution time limit in seconds, this is not model train time out limit
# 604800 <- 7 days
globalTimeLimit <- 604800

setTimeLimit(cpu = globalTimeLimit, elapsed = globalTimeLimit, transient=FALSE)

cpu_cores <- parallel::detectCores(logical=FALSE)
cpu_cores <- as.numeric(cpu_cores)

## Set max number of CPU cores to be used.
## Note: if the underlying model also uses foreach, the## number of cores specified above will double (along with## the memory requirements)
if(cpu_cores > 1 && cpu_cores <= 5){
    CORES <- cpu_cores - 1
    cat(paste0("===> INFO: Adding CPU cores (1): ",CORES," \r\n"))
}else{
    CORES <- cpu_cores
    cat(paste0("===> INFO: Adding CPU cores (3): ",CORES," \r\n"))
}

cat(paste0("===> INFO: Starting PANDORA analysis with ",CORES," CPU cores and ",maximum_memory," MB allocated \r\n"))

queue_start_time <- Sys.time()

# set up the parallel CPU processing
registerDoMC(CORES)

script.dir <- dirname(thisFileLocation())
sourceFile <- paste0(script.dir, "/PANDORA_DATA")

## Configuration variable to detect mode of processing
isStandAlone <- FALSE
if(!file.exists(sourceFile)){
    ## If there is no PANDORA_DATA configuration file it means we are running on stand alone machine
    cat(paste0("===> INFO: Cannot locate source server file, falling back to single server mode! \r\n"))
    isStandAlone <- TRUE
}

if(isStandAlone == FALSE){
    cat(paste0("===> INFO: CRON mode: server \r\n"))


    ## Check if some other R CRON process is already running and KILL it
    process_list <- is_process_running("cron_analysis")
    kill_process_pids(process_list)

    ## Main SERVER data, when machine is created this file is created as-well via cloud-int function
    ## This process is being made via PHP backend api, in php cron task
    ## To run it manually: php public/index.php backend/system/cron
    ## File location: server/backend/source/routes/system/cronJobs.php in createQueueServer function
    serverData <- paste(readLines(sourceFile), collapse=" ")
    serverData <- RCurl::base64Decode(serverData)
    serverData <- jsonlite::fromJSON(serverData)
}else{
    cat(paste0("===> INFO: CRON mode: stand-alone \r\n"))
    ## Get queues that needs processing
    serverData <- getProcessingEntries()
}

if(length(serverData) < 1){
    cat(paste0("===> INFO: Nothing to analyze! Could not detect any queue in database.\r\n"))
    quit()
}else{
    ## Important: when processing is done delete PID file otherwise cron.R will not run next time
    if(!file.exists(UPTIME_PID)){
        file.create(UPTIME_PID)
    }else{
        pid_info <- file.info(UPTIME_PID)
        pid_time_diff <- round(difftime(Sys.time(), pid_info$mtime, units="secs"), digits = 0)

        cat(paste0("===> ERROR: Found PID file ", UPTIME_PID, " Age: ", pid_time_diff," sec. Waiting for existing cron task to finish.\r\n"))

        ## Maybe time limit did not exceeded by some else killed our cron process and its not running anymore!?
        process_list <- is_process_running("cron_analysis")
        ## There are no process running delete PID file so cron can continue on next call
        if(length(process_list) == 0){
            cat(paste0("===> INFO: Deleting PID file, no CRON process is detected as running \r\n"))
            invisible(file.remove(UPTIME_PID))
            file.create(UPTIME_PID)
        }else{
            if(pid_time_diff > globalTimeLimit){
                cat(paste0("===> INFO: Deleting PID file since exceeded global time limit defined of ", globalTimeLimit ," sec \r\n"))
                if(file.exists(UPTIME_PID)){
                    invisible(file.remove(UPTIME_PID))
                }
            }else{
                cat(paste0("===> INFO: Quitting, found ",length(process_list)," running process \r\n"))
                ## Check for ghost processes that are not running anymore
                if(length(process_list) == 1){
                    ## Remove PID file
                    if(file.exists(UPTIME_PID)){
                        cat(paste0("======> INFO: Deleting UPTIME_PID file for ghost process \r\n"))
                        invisible(file.remove(UPTIME_PID))
                    }
                }
                quit()
            }
        }
    }
}

## Dataset queue status: 3 Marked for processing 
queue_status <- 3
## At this stage status og the queue should be changed to 3 - Marked for processing
updateDatabaseFiled("dataset_queue", "status", queue_status, "id", serverData$queueID)

## If more than 1 server is started for specific dataset one must wait while 
## 1st one makes train and test partitions and save them into database, 
## so all other servers can use the same training and testing sets to process different algorithms
generateData <- function(serverData){
    ## 1st - Get JOB and his Info from database
    datasets <- db.apps.getCronJobQueue(serverData)

    if(length(datasets) < 1){
        cat(paste0("===> INFO: Nothing to analyze! No datasets found in database for queueID: ",serverData$queueID," \r\n"))
        invisible(file.remove(UPTIME_PID))
        quit()
    }else{
        cat(paste0("===> INFO: generateData Found ",length(datasets)," resamples for queueID: ",serverData$queueID," \r\n"))
    }
    ## Loop all datasets and make Train and Test Sets if initial server
    for (d in 1:length(datasets)) {
        datasets[[d]]$status <- TRUE
        if(is.na(datasets[[d]]$remotePathMain) == TRUE){
            cat(paste0("===> ERROR: remotePathMain missing for resampleID: ",datasets[[d]]$resampleID,", removing it from processing..\r\n"))
            datasets[[d]]$status <- FALSE
            next()
        }
        # Download and make sets
        if(serverData$internalServerID > 0 && is.na(datasets[[d]]$remotePathTrain) == TRUE){
            ## WAIT
            cat(paste0("===> INFO: Waiting for Tran and Test data to be generated for resampleID: ",datasets[[d]]$resampleID,"! Retrying in 60sec  \r\n"))
            ## The time interval to suspend execution for, in seconds.
            Sys.sleep(60)
            datasets <- generateData(serverData)
            break
        }
        if(serverData$internalServerID == 0 && is.na(datasets[[d]]$remotePathTrain) == TRUE){
            cat(paste0("===> INFO: Generating Tran and Test data resampleID: ",datasets[[d]]$resampleID,"  \r\n"))
            ## If there is no data generated generate it now!!
            preProcessStatus <- preProcessDataset(datasets[[d]]);
            if(preProcessStatus == FALSE){
                cat(paste0("===> ERROR: Cannot preProcess resample: ",datasets[[d]]$resampleID,", removing it from processing..\r\n"))
                datasets[[d]]$status <- FALSE
                next()
            }else{
                datasets <- generateData(serverData)
                break
            }
        }else{
            cat(paste0("===> INFO: Train and Test sets are already generated for: ",datasets[[d]]$resampleID,"! \r\n"))
        }
    }
    return (datasets);
}
## Get data and generate data partitions if necessarily
datasets <- generateData(serverData)

# Simple total/skipped metrics
total_datasets <- length(datasets)
skipped_datasets <- 0

if(total_datasets > 0){
    ## At this stage status of the queue should be changed to 4 - Processing
    queue_status <- 4
    updateDatabaseFiled("dataset_queue", "status", queue_status, "id", serverData$queueID)
}

## Lets sort resample datasets by number of samples so we process one with more samples first
# datasets <- datasets[order(-as.numeric(datasets$samples_total)),]

## MAIN DATASET LOOP START
for (dataset in datasets) {

    if(dataset$status == FALSE){
        skipped_datasets = skipped_datasets + 1
        next()
    }
    ## make garbage collection to take place
    gc()

    resample_time_start <- Sys.time()
    JOB_DIR <- initilizeDatasetDirectory(dataset)
    ## Development overwrite
    ## sink(paste0(JOB_DIR,"/logs/output.txt"))
    cat(paste0("+++> INFO: Started resampleID: ",dataset$resampleID," outcome: ",dataset$outcome," at: ", resample_time_start," Local-path: ",JOB_DIR," <+++\r\n"))

    ## Mark re-sample in database that is currently processing
    updateDatabaseFiled("dataset_resamples", "status", 4, "id", dataset$resampleID)

    data = list(training = "",testing = "")
    outcome_and_classes <- c(dataset$outcome, dataset$classes)

    filePathTraining <- downloadDataset(dataset$remotePathTrain)
    filePathTesting <- downloadDataset(dataset$remotePathTest)

    if(filePathTraining == FALSE || filePathTraining == FALSE){
        message <- paste0("===> ERROR: SKIPPING Dataset processing cannot locate downloaded Training or Testing files \r\n")
        message <- paste0("===> ERROR: SKIPPING INFO: remotePathTrain: ",dataset$remotePathTrain," filePathTraining: ",filePathTraining,"\r\n")
        message <- paste0("===> ERROR: SKIPPING INFO: remotePathTest: ",dataset$remotePathTest," filePathTraining: ",filePathTesting,"\r\n")
        cat(message)
        updateDatabaseFiled("dataset_resamples", "status", 6, "id", dataset$resampleID)
        appendDatabaseFiled("dataset_resamples", "error", message, "id", dataset$resampleID)

        next()
    }

    ## Don't try to make predictions if Training failed or we have less than 10 samples in testing dataset
    if (is.null(dataset$samples_testing) || as.numeric(dataset$samples_testing) <= 10) {
        message <- paste0("===> ERROR: SKIPPING Cannot make predictions on the model, not enough samples in test set (>=10) samples_testing: ",dataset$samples_testing," \r\n")
        cat(message)
        updateDatabaseFiled("dataset_resamples", "status", 6, "id", dataset$resampleID)
        appendDatabaseFiled("dataset_resamples", "error", message, "id", dataset$resampleID)
        next()
    }

    cat(paste0("===> INFO: Reading datasets: Training: ",dataset$remotePathTrain," Testing: ",dataset$remotePathTest," \n"))

    data$training <- loadDataFromFileSystem(filePathTraining)
    data$testing <- loadDataFromFileSystem(filePathTesting)

    ## if(length(dataset$fs_status$error) > 0 && nrow(dataset$fs_status$error) > 0){
    ##     ## Mark Job as Error and quit
    ##     db.apps.setStatusJobQueue(dataset$resampleID, 5, 0)
    ##     cat(paste0("===> INFO: Errors in processing feature set, please correct them and resubmit the job! \r\n"))
    ##     quit()
    ## }
    ## rm(dataset$fs_status)
    outcome_mapping <- getDatasetResamplesMappings(dataset$queueID, dataset$resampleID, dataset$outcome)
    
    ## Coerce data to a standard data.frame
    data$training <- base::as.data.frame(data$training)
    data$testing <- base::as.data.frame(data$testing)

    if("pca" %!in% dataset$preProcess){
        ## Remove all columns expect selected features and outcome
        data$training <- data$training[, base::names(data$training) %in% c(dataset$features, dataset$outcome)]
        data$testing <- data$testing[, base::names(data$testing) %in% c(dataset$features, dataset$outcome)]
    }

    modelData = list(training = data$training, testing = data$testing)
    cat(paste0("===> INFO: Setting factors for datasets on: ",dataset$outcome," column. \n"))

    ## Establish factors for outcome column
    ## Specify library ("base") since some other libraries overwrite as.factor functions like h2o
    modelData$training[[dataset$outcome]] <- base::as.factor(modelData$training[[dataset$outcome]])
    modelData$training[[dataset$outcome]] <- base::factor(
        modelData$training[[dataset$outcome]], levels = base::levels(modelData$training[[dataset$outcome]])
    )
    modelData$testing[[dataset$outcome]] <- base::as.factor(modelData$testing[[dataset$outcome]])
    modelData$testing[[dataset$outcome]] <- base::factor(
        modelData$testing[[dataset$outcome]], levels = base::levels(modelData$testing[[dataset$outcome]])
    )
    
    ## User selected methods
    models_to_process <- dataset$packages$internal_id

    ## list of models that are completely unsupported
    models_restrict <- c("null", "mxnet")
    loaded_libraries_for_model <- c()

    cat(paste0("===> INFO: Starting to process models for the resample \n"))
    ## Loop all user selected methods and make models
    for (model in rev(models_to_process)) {
        ## Checks if user requested to stop current running task
        if(isStandAlone == TRUE){
            if(file.exists(paste0("/tmp/stop_cron_analysis_",serverData$queueID))){ 
                cat(paste0("======> INFO: Stopping current running task UPTIME_PID file \r\n"))
                ## At this stage status of the queue should be changed to 7 - User paused
                queue_status <- 7
                updateDatabaseFiled("dataset_queue", "status", queue_status, "id", serverData$queueID)

                cat(paste0("======> INFO: Deleting UPTIME_PID file \r\n"))
                invisible(file.remove(UPTIME_PID))
            }
        }
        ## Used when saving model to models DB table to set training_time value
        model_time_start <- Sys.time()
        error_models <- c()
        trainModel <- NULL

        model_details <- dataset$packages[dataset$packages$internal_id %in% model,]
        ## Set timeout from database (user selected in Start Analysis) - used for model training
        if(is.null(dataset[["modelProcessingTimeLimit"]])){
            print(dataset)
            model_details$process_timeout <- 300
        }else{
            model_details$process_timeout <- as.numeric(dataset$modelProcessingTimeLimit)
        }
        cat(paste0("===> INFO: Setting model processing timeout limit to: ",model_details$process_timeout," seconds \r\n"))

        model_details$model_specific_args <- NULL
        ## Interface can be formula or matrix
        model_details$interface <- "matrix"
        ## Does models supports probabilities
        model_details$prob <- TRUE

        ## TODO add this in database!
        if(model %in% c("qrnn", "penalized", "pcaNNet", "nnet", "multinom", "avNNet")){
            model_details$model_specific_args <- list(trace=FALSE)

        }else if(model %in% c("lmStepAIC", "glmStepAIC")){
            model_details$model_specific_args <- list(trace=0)

        }else if(model %in% c("sda", "rfRules", "plsRglm", "mxnet", "hda", "deepboost", "brnn", "binda", "bartMachine", "avMxnet", "ORFsvm", "ORFridge", "ORFpls", "ORFlog", "gbm")){
            model_details$model_specific_args <- list(verbose=FALSE)

        }else if(model %in% c("mlpKerasDropoutCost", "mlpKerasDropout", "mlpKerasDecayCost", "mlpKerasDecay")){
            model_details$model_specific_args <- list(verbose=0)

        }else if(model %in% c("stepLDA", "stepQDA")){
            model_details$model_specific_args <- list(output=FALSE)
        }

        if(model %in% models_restrict){
            cat(paste0("===> WARNING: RESTRICTED. Skipping model: ",model," \r\n"))
            next()
        }

        cat(paste0("===> INFO: STARTING Model: ",paste0(model_details$internal_id, " " ,model_details$id," S: ",dataset$samples_total," F: ",length(dataset$features))," analysis at: ",model_time_start,"\r\n"))
        model_info <- caret::getModelInfo(model = model_details$internal_id, regex = FALSE)[[1]]
        is_loaded <- FALSE
        
        problemType <- "classification"
        ## Don t process regression...
        if("Classification" %!in% model_info$type){
            problemType <- "regression"
        }
        ## Does models supports probabilities
        if(is.null(model_info$prob) || base::class(model_info$prob) != "function"){
            model_details$prob <- FALSE
        }
        ## Use formula interface for regression problems
        if(problemType == "regression"){
            model_details$interface <- "formula"
        }

        ## Check if specific model for current feature set is already processed
        model_processed <- db.apps.checkIfModelProcessed(dataset$resampleID, model_details$id)
        if(model_processed == TRUE){
            cat(paste0("===> INFO: SKIPPING Model is already processed. Model: ", model_details$internal_id, "\r\n"))
            next()
        }
        ## Check if Queue Task still exsist (if user deleted a queue while processing was running this will make sure to sop processing as well)
        queue_exsist <- db.apps.checkIfQueueExsist(serverData$queueID)
        if(queue_exsist == FALSE){
            cat(paste0("===> INFO: Queue not found in database. Skipping model processing\r\n"))
            next()
        }
        
        ### Remove previously loaded libraries for previous model
        if(length(loaded_libraries_for_model) > 0){
             cat(paste0("===> INFO: Unloading packages of previous model: ",paste(loaded_libraries_for_model, collapse = ",")," \r\n"))
            for (prev_package in loaded_libraries_for_model) {
                detach_package(prev_package, character.only = TRUE)
            }
            loaded_libraries_for_model <- c()
        }
        if(!is.null(model_info$library)){
            ## Try to load model libraries 
            for (package in unique(c(model_info$library))) {
                if(package %!in% (.packages())){
                    cat(paste0("===> WARNING: Package is not loaded: ",package," - trying to load it \r\n"))

                    if (!require(package, character.only=TRUE, quietly=TRUE, warn.conflicts=FALSE)) {
                        cat(paste0("===> ERROR: Package not found: ",package," trying to install it:\r\n"))
                        github_path <- paste0("cran/", package)
                        if(try(RCurl::url.exists(paste0("https://github.com/",github_path)))){
                            if(!p_load_gh(c(github_path), install = TRUE, update = FALSE, dependencies = TRUE)){
                                cat(paste0("===> ERROR: Package : ",package," could not be installed from github \r\n"))
                                break()
                            }else{
                                cat(paste0("===> SUCESS: Package is successfully loaded: ",package," \r\n"))
                                is_loaded <- TRUE
                                loaded_libraries_for_model <- c(loaded_libraries_for_model, package)
                            }
                        }else{
                            cat(paste0("===> ERROR: Package : ",github_path," not found on github \r\n"))
                            break()
                        }

                    }else{
                        cat(paste0("===> SUCESS: Package is successfully loaded: ",package," \r\n"))
                        is_loaded <- TRUE
                        loaded_libraries_for_model <- c(loaded_libraries_for_model, package)
                    }
                }else{
                    is_loaded <- TRUE
                    loaded_libraries_for_model <- c(loaded_libraries_for_model, package)
                }
            }
        }else{
            ## No special libraries are required
            is_loaded <- TRUE
        }


        if(is_loaded == FALSE){
            cat(paste0("===> ERROR: SKIPPING Package libraries could not be loaded, skipping: ",package," \r\n"))
            next()
        }
        cat(paste0("===> INFO: Model Training Start: ",model_details$internal_id," Interface: ",model_details$interface," problemType: ",problemType," <=== \r\n"))

        ## dataset$preProcess
        trainModel <- caretTrainModel(modelData$training, model_details, problemType, dataset$outcome, NULL, dataset$resampleID, JOB_DIR)

        ## Define results variables
        trainingVariableImportance <- NULL
        predictionObject <- NULL
        predictionProcessed <- NULL
        predictionAUC <- NULL
        prAUC <- NULL
        predictionPostResample <- NULL
        predictionConfusionMatrix <- NULL

        if(trainModel$status == TRUE){
            cat(paste0("===> INFO: Calculating variable importance for model: ",model," \r\n"))
            trainingVariableImportance <- prepareVariableImportance(trainModel$data)
            if (is.null(trainingVariableImportance)) { 
                error_models <- c(error_models, "Cannot calculate variable importance")
            }
        }else{
            error_models <- c(error_models, trainModel$data)
        }
        if(trainModel$status == TRUE){
            cat(paste0("===> INFO: Training of ",model," finished at ", Sys.time(),". Starting with predictions \r\n"))
            ## Test prediction with prediction dataset on our newly training model
            predictionObject <- caretPredict(trainModel$data, modelData$testing, dataset$outcome, model_details)

            cat(paste0("===> INFO: Predictions of ",model," finished. Prediction type: ",predictionObject$type," Interface: ",model_details$interface," \r\n"))

            ## Go to following step only if predictions are successful
            if (predictionObject$status == TRUE) {
                ## RAW predictions
                predictionProcessed <- NULL

                ## TODO: adjust for multiple outcomes!
                ## Calculate for each outcome separately via one-vs-all approach and get median values with multiclass.roc

                positivePredictionValue <- outcome_mapping[1, ]
                negativePredictionValue <- outcome_mapping[2, ]

                ## Make a cutoff and re-level the data
                if(predictionObject$type == "prob"){
                    valuesProcessedCheck <- TRUE
                    if(outcome_mapping[1, ]$class_remapped %in% colnames(predictionObject$predictions)){
                        positivePredictionValue <- outcome_mapping[1, ]
                        negativePredictionValue <- outcome_mapping[2, ]
                    }else{
                        if(outcome_mapping[2, ]$class_remapped %in% colnames(predictionObject$predictions)){
                            cat(paste0("===> ERROR: Could not find any predictions for ",outcome_mapping[1, ]$class_remapped," inverting classes and using ",positivePredictionValue$class_remapped," for positive value. TODO: fix roc plot \r\n"))
                            positivePredictionValue <- outcome_mapping[2, ]
                            negativePredictionValue <- outcome_mapping[1, ]
                        }else{
                            valuesProcessedCheck <- FALSE
                        }
                    }

                    if(valuesProcessedCheck == TRUE){
                        ## Class prediction is based on a 50% probability cutoff. 
                        threshold <- 0.5
                        predictionsTmpCutOff <- base::factor( ifelse(predictionObject$predictions[, positivePredictionValue$class_remapped] > threshold, positivePredictionValue$class_remapped, negativePredictionValue$class_remapped) )
                        ## More than one class is successfully predicted (A & B)
                        if(length(unique(predictionsTmpCutOff)) > 1){
                            tryCatch({
                                predictionProcessed <- relevel(predictionsTmpCutOff, ref = positivePredictionValue$class_remapped)
                            }, error = function(e) {
                                cat("===> ERROR: in predictionProcessed relevel function:", e$message, "\r\n")
                                cat(print(predictionsTmpCutOff))
                                cat(print(positivePredictionValue))
                                predictionProcessed <- NULL
                            })
                        ## Only one unique class is predicted (A)
                        } else if(length(predictionsTmpCutOff) > 1){
                            predictionProcessed <- predictionsTmpCutOff
                        ## Nothing is predicted
                        }else{
                            predictionProcessed <- NULL
                        }
                    }

                }else if(predictionObject$type == "raw"){
                    predictionProcessed <- predictionObject$predictions
                }

                if(!is.null(predictionProcessed)){

                    cat(paste0("===> INFO: Trying to calculate confusionMatrix \r\n"))
                    ## Calculate confusion matrix
                    predConfusionMatrix <- getConfusionMatrix(predictionProcessed, modelData$testing[[dataset$outcome]], model_details)
                    if(predConfusionMatrix$status == TRUE){
                        predictionConfusionMatrix <- predConfusionMatrix$data
                    }else{
                        cat(paste0("===> ERROR: Cannot calculate confusion matrix: ",predConfusionMatrix$data," \r\n"))
                        error_models <- c(error_models, "Cannot calculate confusion matrix")
                    }
                    
                    cat(paste0("===> INFO: Trying to calculate pROC/pAUC, postResample \r\n"))
                    if(predictionObject$type == "prob" && !is.null(predictionObject$predictions)){
                        cat(paste0("===> INFO: Calculating pROC, pAUC \r\n"))

                        predROC <- getPredictROC(modelData$testing[[dataset$outcome]], predictionObject$predictions[, positivePredictionValue$class_remapped], model_details)

                        if(predROC$status == TRUE){
                            predictionAUC <- list(roc = predROC$data, auc = pROC::auc(predROC$data))
                            ## 
                        }else{
                            cat(paste0("===> ERROR: Cannot calculate getPredictROC \r\n"))
                            error_models <- c(error_models, paste0("Cannot calculate getPredictROC", predROC$data))
                        }
                        cat(paste0("===> INFO: Calculating prAUC START\r\n"))
                        predPrAUC <- getPrAUC(predictionProcessed, modelData$testing[[dataset$outcome]], dataset, outcome_mapping)
                        if(predPrAUC$status == TRUE){
                            prAUC <- predPrAUC$data
                        }else{
                            cat(paste0("===> ERROR: Cannot calculate prAUC: ",predPrAUC$data," \r\n"))
                            ## TODO: Show this as warning and not as error, since if there are any errors in model we cannot make Exploration analysis
                            ## error_models <- c(error_models, "Cannot calculate prAUC")
                        }

                    }else if(predictionObject$type == "raw" && !is.null(predictionObject$predictions)){
                        cat(paste0("===> INFO: Calculating getPostResample \r\n"))
                        ## Calculates performance across resamples
                        ## Given two numeric vectors of data, the mean squared error and R-squared are calculated. For two factors, the overall agreement rate and Kappa are determined.
                        predPostResample <- getPostResample(predictionObject$predictions, modelData$testing[,dataset$outcome], model_details)
                        if(predPostResample$status == TRUE){
                            predictionPostResample <- predPostResample$data
                        }else{
                            cat(paste0("===> ERROR: Cannot calculate getPostResample \r\n"))
                            error_models <- c(error_models, "Cannot calculate getPostResample")
                        }
                    }else{
                        error_models <- c(error_models, "Not calculating pROC or pAUC")
                    }
                }else{
                    error_models <- c(error_models, "Cannot calculate prediction probabilities")
                }
            }else{ ## Predict status check
                error_models <- c(error_models, "Cannot make predictions on the trained model")
            }
        } ## Model FAILED check

        ## If we are here we must have something
        # 1. everything is okay length(error_models) == 0
        # 2. something failed length(error_models) > 0

        ## Refresh the list of exist performance variables from database
        performanceVariables <- getAllPerformanceVariables()

        ## Load dplyr since some packages overwrite it
        p_load(dplyr)
        ## Save failed model so we don't process it again
        methodDetails <- db.apps.pandora.saveMethodAnalysisData(
                                                                dataset$resampleID, 
                                                                trainModel,
                                                                predictionConfusionMatrix,
                                                                model_details,
                                                                performanceVariables,
                                                                predictionAUC,
                                                                prAUC,
                                                                predictionPostResample,
                                                                error_models,
                                                                model_time_start
                                                            )


        if(trainModel$status == TRUE){
            if(!is.null(trainingVariableImportance)){
                db.apps.pandora.saveVariableImportance(
                    trainingVariableImportance,
                    methodDetails$modelID
                )
            }
            ## All in one object for user to download
            pandoraData <- list(
                ## General processing info
                info = list(
                    resampleID = dataset$resampleID,
                    problemType = problemType,
                    ## Lets put this here just because convenience
                    data = modelData,
                    ## String name of outcome column
                    outcome = dataset$outcome,
                    ## Mapping for outcome classes
                    outcome_mapping = outcome_mapping,
                    model_details = model_details,
                    db_method_details = methodDetails,
                    ## Data from getProcessingEntries()
                    dataset_queue_options = serverData$selectedOptions
                ),
                ## Model FIT
                training = list(
                    raw = trainModel,
                    varImportance = trainingVariableImportance
                ),
                ## Predictions
                predictions = list(
                    raw = predictionObject,
                    processed = predictionProcessed,
                    AUROC = predictionAUC, 
                    prAUC = prAUC, 
                    postResample = predictionPostResample,
                    confusionMatrix = predictionConfusionMatrix
                )
            )
            saveDataPaths = list(path_initial = "", renamed_path = "", gzipped_path = "", file_path = "")
            ## JOB_DIR is temporarily directory on our local file-system
            saveDataPaths$path_initial <- paste0(JOB_DIR,"/models/modelID_",model_details$internal_id,"_", methodDetails$modelID, ".RData")
            ## Save data in .RData since write_feather supports only data-frames
            save(pandoraData, file = saveDataPaths$path_initial)
            path_details = compressPath(saveDataPaths$path_initial)
            
            saveDataPaths$renamed_path = path_details$renamed_path
            saveDataPaths$gzipped_path = path_details$gzipped_path

            saveDataPaths$file_path = uploadFile(dataset$userID, saveDataPaths$gzipped_path, paste0("analysis/",serverData$queueID,"/",dataset$resampleID,"/models"))
            file_id <- db.apps.pandora.saveFileInfo(dataset$userID, saveDataPaths)

            if(!is.null(file_id)){
                updateDatabaseFiled("models", "ufid", file_id, "id", methodDetails$modelID)    
            }else{
                updateDatabaseFiled("models", "status", 0, "id", methodDetails$modelID)
                message <- paste0("Error saving model information file")
                appendDatabaseFiled("models", "error", message, "id", methodDetails$modelID)

                error_models <- c(error_models, message)
            }
            
            if(file.exists(saveDataPaths$gzipped_path)){ file.remove(saveDataPaths$gzipped_path) }
            if(file.exists(saveDataPaths$renamed_path)){ file.remove(saveDataPaths$renamed_path) }
        }

        if(length(error_models) > 0){
            cat(paste0("===> ERROR: Training of ",model," failed with ",length(error_models)," following errors: \r\n"))
            cat(paste0("===>        ", paste(error_models, collapse = " | "), "\r\n"))
            ## Clear all processes that are in "hang" state from that method
            ## process_list <- is_process_running("cron_analysis")
            ## https://rdrr.io/cran/fscaret/src/R/timeout.R
        }

        # rm(trainModel)
    } ## END caret model/algorithm loop

    cat(paste0("===> INFO: Processing of resample ID: ",dataset$resampleID," END \r\n"))

    resample_total_time <- calculateTimeDifference(resample_time_start, unit = "ms")
    incrementDatabaseFiled("dataset_resamples", "processing_time", resample_total_time, "id", dataset$resampleID)
    ## 5 - Finished Success
    updateDatabaseFiled("dataset_resamples", "status", 5, "id", dataset$resampleID)

} ## MAIN RESAMPLE DATASET LOOP END

queue_total_time <- calculateTimeDifference(queue_start_time, unit = "ms")
incrementDatabaseFiled("dataset_queue", "processing_time", queue_total_time, "id", serverData$queueID)

## If we skipped all resamples mark queue as failed
if(skipped_datasets >= total_datasets){
    queue_status <- 6 # Finished - Errors
}else{
    queue_status <- 5 # Finished - Success
}

updateDatabaseFiled("dataset_queue", "status", queue_status, "id", serverData$queueID)

cat(paste0("======> INFO: PROCESSING END (",queue_total_time," ms)  \r\n"))

## Remove PID file
if(file.exists(UPTIME_PID)){
    cat(paste0("======> INFO: Deleting UPTIME_PID file \r\n"))
    invisible(file.remove(UPTIME_PID))
}

## Make sure there aren't any cron_analysis child processes from parallel:: package_version still running
process_list <- is_process_running("cron_analysis")
## If there are process still running
if(length(process_list) > 0){
    cat(paste0("===> INFO: Found abandoned process at end of analysis \r\n"))
    # kill $(ps aux | grep 'cron_analysis' | awk '{print $2}') 
    kill_process_pids(process_list)
}

cat(paste0("======> DONE \r\n"))
