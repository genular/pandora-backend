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
createDataPartitions <- function(data, outcome = "outcome", split = 0.75, use.validation = FALSE)
{
    set.seed(1337)
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
# List all predict functions
# for(fn in methods("predict")){
# try({
#         f <- eval(substitute(getAnywhere(fn)$objs[[1]], list(fn = fn)))
#         cat(fn, ":\n\t", deparse(args(f)), "\n")
#     }, silent = TRUE)
# }
# https://machinelearningmastery.com/pre-process-your-dataset-in-r/
# http://rismyhammer.com/ml/Pre-Processing.html
preProcessData <- function(data, outcome, excludeClasses, methods = c("center", "scale"))
{
    set.seed(1337)
    if(length(methods) == 0){
        methods <- c("center", "scale")
    }
    if(!is.null(excludeClasses)){
        whichToExclude <- sapply( names(data), function(y) any(sapply(excludeClasses, function(excludeClass)  return (y %in% excludeClass) )) )
        dataset <- data[!whichToExclude]
    }else{
        dataset <- data
    }

    ### Make sure that ordering is correct!
    value = c("medianImpute", "bagImpute", "knnImpute", "expoTrans", "YeoJohnson", "BoxCox", "center", "scale", "range", "ica", "spatialSign", "zv", "nzv", "conditionalX", "pca", "corr")
    processing_values <- data.frame(value, stringsAsFactors=FALSE)
    processing_values$order <- as.numeric(row.names(processing_values))

    methods_sorted <- processing_values %>% filter(value %in% methods) %>% arrange(order) %>% select(value)
    methods_sorted <- methods_sorted$value

    transformations <- paste(methods_sorted, sep=",", collapse = ",")
    message <- paste0("===> INFO: Pre-processing transformation sorted (",transformations,") \r\n")
    cat(message)

    if(length(colnames(dataset)) < 2){
        message <- paste0("===> INFO: Pre-processing less than 2 columns detected removing some preprocessing methods\r\n")
        cat(message)
        ## Remove correlation if we have less than 2 columns
        methods_sorted <- setdiff(methods_sorted, c("corr", "zv", "nzv", "pca"))
    }

    # calculate the pre-process parameters from the dataset
    if(!is.null(outcome)){
        preprocessParams <- caret::preProcess(dataset, method = methods_sorted, outcome = outcome, n.comp = 25, verbose = TRUE, cutoff = 0.5)    
    }else{
        preprocessParams <- caret::preProcess(dataset, method = methods_sorted, n.comp = 25, verbose = TRUE)   
    }
    # transform the dataset using the parameters
    processedMat <- predict(preprocessParams, newdata=dataset)

    if(!is.null(excludeClasses)){
        # summarize the transformed dataset
        processedMat[excludeClasses] <- data[excludeClasses]
    }

    return(list(processedMat = processedMat, preprocessParams = preprocessParams))
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
