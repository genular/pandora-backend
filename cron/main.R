#!/usr/bin/Rscript --vanilla

## Warning: This CRON should be run called in following way:
## * * * * * /usr/bin/flock -n /tmp/simon_backend.pid /path/to/cron.R

source("server/includes/header.R")

SIMON_PID <- paste0(DATA_PATH,"/simon_r_cron_",SERVER_NAME,".pid")

# for parallel CPU processing
p_load(doMC)
p_load(caret)
p_load(ggplot2)

source("cron/functions/database.R")
source("cron/functions/helpers.R")
source("cron/functions/caretPredict.R")
source("cron/functions/variable_importance.R")
source("cron/functions/preProcessDataset.R")

## options(warn=0)
options(max.print=1000000)
##  maximum size of memory allocation pool
options(java.parameters = "-Xmx16000M")
options(stringsAsFactors=FALSE)
## request a new limit, in Mb
## memory.limit(size = 48000)

## Dataset queue status: 3 Marked for processing 
global_status <- 3

# Set global execution time limit in seconds!
# 604800 <- 7 days
globalTimeLimit <- 604800
setTimeLimit(cpu = globalTimeLimit, elapsed = globalTimeLimit, transient=FALSE)

cpu_cores <- detectCores(logical = TRUE)
cpu_cores <- as.numeric(cpu_cores)

if(cpu_cores > 3){
    CORES <- cpu_cores - 3    
}else{
    CORES <- 1
}

start_time <- Sys.time()

# set up the parallel CPU processing
registerDoMC(CORES)  #use X cores

script.dir <- dirname(thisFileLocation())
sourceFile <- paste0(script.dir, "/SIMON_DATA")

## Configuration variable to detect mode of processing
isStandAlone <- FALSE
if(!file.exists(sourceFile)){
    ## If there is no SIMON_DATA configuration file it means we are running on stand alone machine
    cat(paste0("===> INFO: Cannot locate source server file, falling back to single server mode! \r\n"))
    isStandAlone <- TRUE
}

if(isStandAlone == FALSE){
    cat(paste0("===> INFO: CRON mode: server \r\n"))

    ## Check if some other R CRON process is already running and KILL it
    process_pid <- Sys.getpid()
    process_list <- system("ps -ef | awk '$NF~\"simon-analysis\" {print $2}'", intern = TRUE)
    if(length(process_list) > 0){
        process_list <- setdiff(process_list, process_pid)
        if(length(process_list) > 0){
            for(cron_pid in process_list){
                print(paste0("Killing process SIGKILL: ", cron_pid))
                tools::pskill(as.numeric(cron_pid), signal = 9)
            }
        }
    }

    ## Main SERVER data, when machine is created this file is created as-well via cloud-int function
    ## This process is being made via PHP backend api, in php cron task
    ## To run it manually: php public/index.php backend/system/cron
    ## File location: server/backend/source/routes/system/cronJobs.php in createQueueServer function
    serverData <- paste(readLines(sourceFile), collapse=" ")
    serverData <- RCurl::base64Decode(serverData)
    serverData <- jsonlite::fromJSON(serverData)
}else{
    cat(paste0("===> INFO: CRON mode: stand-alone \r\n"))
    serverData <- getProcessingEntries()
}

if(length(serverData) < 1){
    cat(paste0("===> INFO: Nothing to analyze! Could not detect any queue in database.\r\n"))
    quit()
}else{
    ## Important: when processing is done delete PID file otherwise cron.R will not run next time
    if(!file.exists(SIMON_PID)){
        file.create(SIMON_PID)
    }else{
        pid_info <- file.info(SIMON_PID)
        pid_time_diff <- round(difftime(Sys.time(), pid_info$mtime, units="secs"), digits = 0)

        cat(paste0("===> ERROR: Found PID file ", SIMON_PID, " Age: ", pid_time_diff," sec. Waiting for existing cron task to finish.\r\n"))

        # if(pid_time_diff > globalTimeLimit){
        #     cat(paste0("===> INFO: Deleting PID file since exceeded global time limit of ", globalTimeLimit ," sec \r\n"))
        #     if(file.exists(SIMON_PID)){
        #         invisible(file.remove(SIMON_PID))
        #     }
        # }else{
        #     quit()
        # }
        quit()
    }
}

## At this stage status og the queue should be changed to 3 - Marked for processing
updateDatabaseFiled("dataset_queue", "status", global_status, "id", serverData$queueID)

## If more than 1 server is started for specific dataset one must wait while 
## 1st one makes train and test partitions and save them into database, 
## so all other servers can use the same training and testing sets to process different algorithms
generateData <- function(serverData){
    ## 1st - Get JOB and his Info from database
    datasets <- db.apps.getCronJobQueue(serverData)

    if(length(datasets) < 1){
        cat(paste0("===> INFO: Nothing to analyze! No datasets found in database for queueID: ",serverData$queueID," \r\n"))
        invisible(file.remove(SIMON_PID))
        quit()
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
            preProcessDataset(datasets[[d]]);
            datasets <- generateData(serverData)
            break
        }else{
            cat(paste0("===> INFO: Train and Test sets are already generated for: ",datasets[[d]]$resampleID,"! Skipping...  \r\n"))
        }
    }
    return (datasets);
}
## Get data and generate data partitions if necessarily
datasets <- generateData(serverData)

performanceVariables <- NULL
if(length(datasets) > 0){
    performanceVariables <- getAllPerformanceVariables()
    ## At this stage status of the queue should be changed to 4 - Processing
    updateDatabaseFiled("dataset_queue", "status", global_status, "id", serverData$queueID)
}

## MAIN DATASET LOOP START
for (dataset in datasets) {

    if(dataset$status == FALSE){
        next()
    }

    resample_time_start <- Sys.time()

    JOB_DIR <- initilizeDatasetDirectory(dataset)
    ## Development overwrite
    ## sink(paste0(JOB_DIR,"/logs/output.txt"))
    cat(paste0("+++> INFO: Started resampleID: ",dataset$resampleID," at: ", resample_time_start," Local-path: ",JOB_DIR," <+++\r\n"))

    ## Mark re-sample in database that is currently processing
    updateDatabaseFiled("dataset_resamples", "status", 3, "id", dataset$resampleID)

    data = list(training = "",testing = "")
    outcome_and_classes <- c(dataset$outcome, dataset$classes)

    filePathTraining <- downloadDataset(dataset$remotePathTrain, FALSE)
    filePathTesting <- downloadDataset(dataset$remotePathTest, FALSE)

    if(filePathTraining == FALSE || filePathTraining == FALSE){
        cat(paste0("===> ERROR: SKIPPING Dataset processing cannot locate Training or Testing files \r\n"))
        next()
    }

    cat(paste0("===> INFO: Reading datasets: Training: ",dataset$remotePathTrain," Testing: ",dataset$remotePathTest," \n"))

    data$training <- data.table::fread(filePathTraining, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)
    data$testing <- data.table::fread(filePathTesting, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE)

    ## if(length(dataset$fs_status$error) > 0 && nrow(dataset$fs_status$error) > 0){
    ##     ## Mark Job as Error and quit
    ##     db.apps.setStatusJobQueue(dataset$resampleID, 5, 0)
    ##     cat(paste0("===> INFO: Errors in processing feature set, please correct them and resubmit the job! \r\n"))
    ##     quit()
    ## }
    ## rm(dataset$fs_status)
    outcome_mapping <- getDatasetResamplesMappings(dataset$queueID, dataset$resampleID, dataset$outcome)
    
    ## Coerce data to a standard data.frame
    data$training <- as.data.frame(data$training)
    data$testing <- as.data.frame(data$testing)

    ## Remove all columns expect selected features and outcome
    data$training <- data$training[, names(data$training) %in% c(dataset$features, dataset$outcome)]
    data$testing <- data$testing[, names(data$testing) %in% c(dataset$features, dataset$outcome)]

    ## User selected methods
    models_to_process <- dataset$packages$internal_id

    ## list of models that are completely unsupported
    ## models_restrict <- c("awnb", "awtan", "bag", "bagEarth", "bagEarthGCV", "bagFDA", "bagFDAGCV", "bam", "bartMachine", "extraTrees", "gbm_h2o", "hdrda", "RWeka", "J48", "JRip", "LMT", "PART", "OneR", "oblique.tree","xyf", "glmnet_h2o", "mlpSGD")
    models_restrict <- c("null", "mxnet")

    loaded_libraries_for_model <- NULL
    ## Loop all user selected methods and make models
    for (model in rev(models_to_process)) {
        ## Used when saving model to models DB table to set training_time value
        model_time_start <- Sys.time()

        model_details <- dataset$packages[dataset$packages$internal_id %in% model,]
        ##   id internal_id classification regression
        ## 3854          lm              0          1

        if(model %in% models_restrict){
            cat(paste0("===> WARNING: RESTRICTED. Skipping model: ",model," \r\n"))
            next()
        }

        sucess <- TRUE
        error_models <- c()

        cat(paste0("===> INFO: STARTING Model: ",paste0(model_details$internal_id, " " ,model_details$id," S: ",dataset$samples_total," F: ",length(dataset$features))," analysis at: ", Sys.time(),"\r\n"))
        model_info <- caret::getModelInfo(model = model_details$internal_id, regex = FALSE)[[1]]

        is_loaded <- FALSE
        
        problemType <- "classification"
        ## Don t process regression...
        if("Classification" %!in% model_info$type){
            ## cat(paste0("===> ERROR: SKIPPING Only Classification models are supported. Current model: ", model, " Class Type: ", model_info$type, "\r\n"))
            ## next()
            problemType <- "regression"
        }
        if(is.null(model_info$prob) || class(model_info$prob) != "function"){
            model_details$prob <- FALSE
        }else{
            model_details$prob <- TRUE
        }

        ## TODO: make this as little times as possible
        modelData = list(training = data$training, testing = data$testing)
        if(problemType == "classification"){
            ## Establish factors for outcome column, but only for classification problems
            modelData$training[[dataset$outcome]] <- as.factor(modelData$training[[dataset$outcome]])
            modelData$training[[dataset$outcome]] <- factor(
                modelData$training[[dataset$outcome]], levels = levels(modelData$training[[dataset$outcome]])
            )
            modelData$testing[[dataset$outcome]] <- as.factor(modelData$testing[[dataset$outcome]])
            modelData$testing[[dataset$outcome]] <- factor(
                modelData$testing[[dataset$outcome]], levels = levels(modelData$testing[[dataset$outcome]])
            )
        }


        ## Check if specific model for current feature set is already processed
        model_processed <- db.apps.checkIfModelProcessed(dataset$resampleID, model_details$id)
        if(model_processed == TRUE){
            cat(paste0("===> ERROR: SKIPPING Model is already processed. Model: ", model_details$internal_id, "\r\n"))
            next()
        }
        ### Remove previously loaded libraries for previous model
        if(!is.null(loaded_libraries_for_model)){
             cat(paste0("===> INFO: Unloading packages of previous model: ",paste(loaded_libraries_for_model, collapse = ",")," \r\n"))
            for (prev_package in loaded_libraries_for_model) {
                detach_package(prev_package)
            }
            loaded_libraries_for_model <- NULL
        }
        if(!is.null(model_info$library)){
            ## Try to load model libraries 
            for (package in c(model_info$library)) {
                if(package %!in% (.packages())){
                    cat(paste0("===> WARNING: Package is not loaded: ",package," - trying to load it! \r\n"))
                    if (!p_load(c(package), install = TRUE, character.only = TRUE)) {
                        cat(paste0("===> ERROR: Package not found: ",package," \r\n"))
                        break()
                        ## Development override
                        ## install.packages(package, dependencies = TRUE, repos="http://cran.us.r-project.org")
                        ## if (require(package, character.only=T, quietly=T)) {
                        ##     is_loaded <- TRUE
                        ##     loaded_libraries_for_model <- c(loaded_libraries_for_model, package)
                        ## }
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
            cat(paste0("===> ERROR: SKIPPING Package could not be loaded, skipping: ",package," \r\n"))
            # mxnet is pain in the ***!
            # if(package != "mxnet"){
            #     invisible(file.remove(SIMON_PID))
            #     quit()
            # }
            next()
        }
        cat(paste0("===> INFO: model training start: ",model_details$internal_id," \r\n"))

        trainModel <- caretTrainModel(modelData$training, model_details, problemType, dataset$outcome, NULL, dataset$resampleID, JOB_DIR)

        ## Define results variables
        results_auc <- NULL
        results_confusionMatrix <- NULL
        results_varImportance <- NULL

        if (trainModel$status == TRUE) {
            cat(paste0("===> INFO: Training finished: ",model," at: ", Sys.time()," \r\n"))

            ## Test prediction with prediction dataset on our newly training model
            prediction <- caretPredict(trainModel$data, modelData$testing)

            ## RAW predictions
            prediction_raw <- NULL
            ## Probability predictions
            prediction_prob <- NULL

            if(prediction$type == "prob"){
                prediction_prob <- prediction$preds

                ## Cass prediction is based on a 50% probability cutoff. 
                threshold <- 0.5
                prediction_raw <- factor( ifelse(prediction_prob[, outcome_mapping[1, ]$class_remapped] > threshold, outcome_mapping[1, ]$class_remapped, outcome_mapping[2, ]$class_remapped) )
   
                ## More than one class is successfully calculated
                if(length(unique(prediction_raw)) > 1){
                    prediction_raw      <- relevel(prediction_raw, outcome_mapping[1, ]$class_remapped)
                ## Only one unique class is calculated
                } else if(length(prediction_raw) > 1){
                    prediction_raw      <- prediction_raw
                }else{
                    prediction_raw <- NULL
                }

            }else if(prediction$type == "raw"){
                prediction_raw <- prediction$preds
            }

            if(!is.null(prediction_raw) || !is.null(prediction_prob)){
                if(problemType == "regression" && !is.null(prediction_prob)){
                    ## Calculates performance across resamples
                    ## Given two numeric vectors of data, the mean squared error and R-squared are calculated. For two factors, the overall agreement rate and Kappa are determined.
                    t <- apply(prediction_prob, 2, caret::postResample, obs = modelData$testing[[dataset$outcome]])
                }

                if(!is.null(prediction_raw)){
                    results_confusionMatrix <- caret::confusionMatrix(prediction_raw, modelData$testing[[dataset$outcome]])
                }

                if(!is.null(prediction_prob)){
                    roc_p <- pROC::roc(modelData$testing[[dataset$outcome]], prediction_prob[, outcome_mapping[1, ]$class_remapped], levels = levels(modelData$testing[[dataset$outcome]]))
                    results_auc <- list(roc = roc_p, auc = pROC::auc(roc_p))
                }

                results_varImportance <- prepareVariableImportance(trainModel$data)

                if (is.null(results_varImportance)) { 
                    sucess <- FALSE
                    error_models <- c(error_models, "Cannot calculate variable importance")
                }
            }else{
                sucess <- FALSE
                error_models <- c(error_models, "Cannot calculate predict probabilities")
            }

        }else{
            sucess <- FALSE
            error_models <- c(error_models, "Could not train model, errors occurred")
        }
        
        ## Save failed model so we don't process it again
        methodDetails <- db.apps.simon.saveMethodAnalysisData(dataset$resampleID, 
                                                      trainModel,
                                                      results_confusionMatrix,
                                                      model_details,
                                                      performanceVariables,
                                                      results_auc, 
                                                      as.numeric(sucess),
                                                      error_models,
                                                      model_time_start)

        if(sucess != FALSE){
            global_status <- 5 # Finished - Sucess

            db.apps.simon.saveVariableImportance(
                results_varImportance,
                methodDetails$modelID
            )

            saveData <- list(
                training = trainModel,
                prediction = prediction, 
                auc = results_auc, 
                confusionMatrix = results_confusionMatrix,
                varImportance = results_varImportance
            )

            saveDataPaths = list(path_initial = "", renamed_path = "", gzipped_path = "", file_path = "")
            ## JOB_DIR is temporarily directory on our local file-system
            saveDataPaths$path_initial <- paste0(JOB_DIR,"/models/modelID_", methodDetails$modelID, ".RData")

            ## Save data in .RData since write_feather supports only data-frames
            save(saveData, file = saveDataPaths$path_initial)
            rm(saveData)

            path_details = compressPath(saveDataPaths$path_initial)
            
            saveDataPaths$renamed_path = path_details$renamed_path
            saveDataPaths$gzipped_path = path_details$gzipped_path

            saveDataPaths$file_path = uploadFile(dataset$userID, saveDataPaths$gzipped_path, paste0("analysis/",serverData$queueID,"/",dataset$resampleID,"/models"))

            file_id <- db.apps.simon.saveFileInfo(dataset$userID, saveDataPaths)

            updateDatabaseFiled("models", "ufid", file_id, "id", methodDetails$modelID)

            if(file.exists(saveDataPaths$gzipped_path)){ file.remove(saveDataPaths$gzipped_path) }
            if(file.exists(saveDataPaths$renamed_path)){ file.remove(saveDataPaths$renamed_path) }

        }else{
            global_status <- 6 ## Finished - Errors 
        }
        rm(trainModel)
    } ## END caret model/algorithm loop

    resample_time_end <- Sys.time()
    resample_total_time <- as.numeric(difftime(resample_time_end, resample_time_start,  units = c("secs")))
    resample_total_time_ms <- ceiling(resample_total_time * 1000)
    updateDatabaseFiled("dataset_resamples", "processing_time", resample_total_time_ms, "id", dataset$resampleID)
    ## 4 - Finished Success
    updateDatabaseFiled("dataset_resamples", "status", 4, "id", dataset$resampleID)

} ## MAIN DATASET LOOP END

end_time <- Sys.time()
total_time <- as.numeric(difftime(end_time, start_time,  units = c("secs")))
total_time_ms <- ceiling(total_time * 1000)

updateDatabaseFiled("dataset_queue", "processing_time", total_time_ms, "id", serverData$queueID)
updateDatabaseFiled("dataset_queue", "status", global_status, "id", serverData$queueID)

cat(paste0("======> INFO: PROCESSING END (",total_time," sec) \r\n"))
## Remove PID file
if(file.exists(SIMON_PID)){
    cat(paste0("======> INFO: Deleting SIMON_PID file \r\n"))
    invisible(file.remove(SIMON_PID))
}