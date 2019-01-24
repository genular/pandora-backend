# Function eval_fork() of opencpu package modified
# Original code by Jeroen Ooms <jeroen.ooms at stat.ucla.edu> of OpenCPU package
# 
predictTimeout <- function(..., seconds) {

    fork_to_check <- parallel::mcparallel(
        {eval(...)},
        silent = FALSE)
    # call mccollect to wait "seconds" for returning result of mcparallel.
    result <- parallel::mccollect(fork_to_check, wait = FALSE, timeout = seconds)
    # If result is returned kill fork
    tools::pskill(fork_to_check$pid, tools::SIGKILL)
    tools::pskill(-1 * fork_to_check$pid, tools::SIGKILL)
    # kill the fork of forks if they were spawned
    parallel::mccollect(fork_to_check, wait = FALSE)
    # If the function mccollect had NULL (timedout), make stop
    if (is.null(result)){
        result <- paste0("INFO: predictTimeout limit ",seconds," sec has been reached!")
    }else{
        # remove list format
        result <- result[[1]]
    }

    # return result
    return(result)
}

MSE <-function(vect1, vect2, rows_no){
    result=0
    pred<-0
    obs<-0
    for(i in 1:rows_no){
        result<-result +(vect1[i]-vect2[i])^2
    }
    result<-(result/rows_no)
    return(result)
}

RMSE <- function(vect1, vect2, rows_no){
    result=0
    obs<-0
    pred<-0
    for(i in 1:rows_no){
        result<-result +(vect1[i]-vect2[i])^2
    }
    result<-(result/rows_no)^0.5
    return(result)
}

# The dataset requires defined training and test subsets so let's
# remove some of the variables that don't see to add to the value and
# create these
createDataPartitions <- function(data, outcome = "outcome", split = 0.75, use.validation= FALSE)
{
    set.seed(1234)
    validation <- NULL

    # Split data: 75% training, 25% testing.
    inTrain <- caret::createDataPartition(y = as.character(data[[outcome]]), times = 1, p = split, list = FALSE, groups = min(5, length(data[[outcome]])) )

    training <<- data[inTrain,]
    testing <<- data[-inTrain,]

    # If using validation set, split data: 45% training, 30% validation, 25% testing.
    if(use.validation) {
        inValidation <<- caret::createDataPartition(y = data[[outcome]], p=.4, list=FALSE)
        validation <<- training[inValidation,]
        training <<- training[-inValidation,]
    }

    list(training = training, testing = testing, validation = validation)
}
## List all predict functions
## for(fn in methods("predict"))
##    try({
##        f <- eval(substitute(getAnywhere(fn)$objs[[1]], list(fn = fn)))
##        cat(fn, ":\n\t", deparse(args(f)), "\n")
##        }, silent = TRUE)
## https://machinelearningmastery.com/pre-process-your-dataset-in-r/
preProcessData <- function(data, outcome, excludeClasses, methods = c("center", "scale"))
{
    set.seed(1337)
    whichToExclude <- sapply( names(data), function(y) any(sapply(excludeClasses, function(excludeClass)  return (y %in% excludeClass) )) )
    # calculate the pre-process parameters from the dataset
    preprocessParams <- caret::preProcess(data[!whichToExclude], method = methods, outcome = outcome)
    # transform the dataset using the parameters
    processedMat <- predict(preprocessParams, newdata=data[!whichToExclude])

    # summarize the transformed dataset
    data[!whichToExclude] <- processedMat

    return(data)
}

findImportantVariables  <- function(max_auc, min_auc, min_score, max_score, min_rank, max_rank, json_features, processing_id) {

    cat(paste0("===> INFO: Feature pre-processing step is finished, starting post-processing. 
        Using max_auc: ",max_auc," min_auc: ",min_auc," min_score: ",min_score," max_score: ",max_score,"\r\n"))
    
    results <- json_features

    feature_sets <- db.geatAllFeatureSets(processing_id, "initial")

    auc_step <- seq(min_auc,max_auc, by=0.01)
    score_step <- seq(min_score,max_score, by=5)
    rank_step <- seq(min_rank, max_rank, by=3)

    predicted_counter <- 0

    if(!is.null(feature_sets)){
        for(fs_step in 1:nrow(feature_sets)){
            fs_id <- feature_sets[fs_step, ]

            for (i in 1:length(auc_step)) {
                auc <- auc_step[i]

                for (s in 1:length(score_step)) {
                    score <- score_step[s]

                    for (r in 1:length(rank_step)) {
                        rank <- round(rank_step[r])
                        features <- db.getMostImportantFeatures(auc, score, rank, fs_id, processing_id)

                        print(cat(paste0("==> INFO: FS_ID: ",fs_id," AUC: ",auc," SCORE: ",score," RANK: ",rank,"\r\n")))

                        if (features$feature_count > 3 && features$donors_count > 20) {
                            if(features$features_hash %!in% results$features_hash){
                                results <- rbind(results, features)
                                predicted_counter <- predicted_counter + 1
                            }
                        }
                    }
                }
            }                
        }
    }

    ## testing <- results[, c("feature_count","features_hash","donors_count","data_source","sql")]
    ## write.csv(testing, file = "features.csv")
    ## print(results[, c("feature_count","features_hash","donors_count","data_source")])
    ## q()

    return(results)
}
