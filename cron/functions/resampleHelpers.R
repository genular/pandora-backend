loadGlobalDataset <- function(remotePathMain, resampleID){

    filepath_extracted <- downloadDataset(remotePathMain)

    ## If data is missing cancel processing! 
    if(filepath_extracted == FALSE){
        success <- FALSE

        message <- paste0("===> ERROR: Cannot download remote dataset data: ",remotePathMain," \r\n")
        cat(message)

        updateDatabaseFiled("dataset_resamples", "status", 6, "id", resampleID)
        appendDatabaseFiled("dataset_resamples", "error", message)
        return(success)
    }

    globalDataset <- loadDataFromFileSystem(filepath_extracted)

    return(globalDataset)
}

checkSelectedOutcomeColumns <- function(selectedOutcomeColumns, resampleID){
    success <- TRUE

    if(length(selectedOutcomeColumns) != 1){
        success <- FALSE
        message <- paste0("===> ERROR: Invalid number (",length(selectedOutcomeColumns),") of outcome columns detected. Currently only one is supported.")
        cat(message)

        updateDatabaseFiled("dataset_resamples", "status", 6, "id", resampleID)
        appendDatabaseFiled("dataset_resamples", "error", message)
    }

    return(success)
}

checkSelectedOutcomeValues <- function(datasetData, selectedOutcomeColumns){
    success <- TRUE

    outcome_unique <- unique(datasetData[[selectedOutcomeColumns]])
    outcome_unique_count <- length(outcome_unique)

    if(outcome_unique_count < 2 || outcome_unique_count > 702){
        success <- FALSE
        cat(paste0("===> ERROR: You have: ", outcome_unique_count, " outcome class. You should have anything between 2-702 including 2 and 702.\r\n"))
        print(outcome_unique)
    }

    na_check <- as.numeric(sum(is.na(datasetData[[selectedOutcomeColumns]])))
    
    if(na_check > 0){
        success <- FALSE
        cat(paste0("===> ERROR: NA Values found in outcome column: ",selectedOutcomeColumns,"\r\n"))
        print(outcome_unique)    
    }
    
    return(success)
}

generateResampleMappings <- function(datasetData, selectedOutcomeColumns, outcome_and_classes, queueID, resampleID){
    outcome_unique <- unique(datasetData[[selectedOutcomeColumns]])
    outcome_unique_count <- length(outcome_unique)

    ## Remap outcome classes with A & B values
    mappings <- matrix(ncol=4, nrow=outcome_unique_count)

    ## Generate letters: LIMIT: 702 letters
    outcome_remapping <- c(LETTERS, sapply(LETTERS, function(x) paste0(x, LETTERS)))
    ## Convert "outcome" to characters and then do replacing
    datasetData[[selectedOutcomeColumns]] <- as.character(datasetData[[selectedOutcomeColumns]])

    m_count <- 1
    remap_count <- 1
    for(outcome_item in outcome_unique){
        mappings[m_count, ][1] <- selectedOutcomeColumns
        mappings[m_count, ][2] <- 2
        mappings[m_count, ][3] <- outcome_item
        mappings[m_count, ][4] <- outcome_remapping[remap_count]

        datasetData[[selectedOutcomeColumns]][datasetData[[selectedOutcomeColumns]] == outcome_item] <- outcome_remapping[remap_count]
        m_count <- m_count + 1
        remap_count <- remap_count + 1
    }


    ## Extract all non numeric column values and convert them to numeric
    non_numeric_column_ids <- unlist(lapply(datasetData[, !names(datasetData) %in% outcome_and_classes] , is.numeric))  
    non_numeric_column_names <- colnames(datasetData)[!non_numeric_column_ids]

    if(length(non_numeric_column_names) > 0){
        for (column_name in non_numeric_column_names){
            column_unique <- unique(datasetData[[column_name]])

            ## Extend the matrix
            mappings <- rbind(mappings, length(column_unique))

            column_remapping <- seq(1, length(column_unique), by=1)
            ## Convert "column" to characters and then do replacing
            datasetData[[column_name]] <- as.character(datasetData[[column_name]])

            remap_count <- 1
            ##   class_column class_type class_original class_remapped
            ## 1      column0          2       cyclists              A
            ## 2      column0          2   noncyclists               B
            ## 3      column0          2 wannabecyclist              C
            for(column_item in column_unique){
                ## class_column
                mappings[m_count, ][1] <- column_name
                ## class_type
                mappings[m_count, ][2] <- 2
                ## class_original
                mappings[m_count, ][3] <- column_item
                ## class_remapped
                mappings[m_count, ][4] <- column_remapping[remap_count]

                datasetData[[column_name]][datasetData[[column_name]] == column_item] <- column_remapping[remap_count]
                m_count <- m_count + 1
                remap_count <- remap_count + 1
            }
        }
    }

    ## Convert it to data-frame
    mappings <- as.data.frame(mappings)
    colnames(mappings) <- c("class_column", "class_type", "class_original", "class_remapped")

    query <- paste0("INSERT IGNORE INTO `dataset_resamples_mappings` 
                        (`id`, `dqid`, `drid`, `class_column`, `class_type`, `class_original`, `class_remapped`, `created`) 
                    VALUES", paste(sprintf("(NULL, '%s', '%s', '%s', '%s', '%s', '%s', NOW())", queueID, resampleID,
        mappings$class_column, mappings$class_type, mappings$class_original, mappings$class_remapped), collapse = ","))

    results <- dbExecute(databasePool, query)

    return(list(mappings = mappings, datasetData = datasetData))

}

ramapColumnValuesByMappings <- function(datasetData, resampleMappings, mapFrom = "class_original", mapTo = "class_remapped"){

	for(i in 1:nrow(resampleMappings)) {
	    mapping <- resampleMappings[i,]
        ## Convert "column" to characters and then do replacing
        datasetData[[mapping$class_column]] <- as.character(datasetData[[mapping$class_column]])
        datasetData[[mapping$class_column]][datasetData[[mapping$class_column]] == mapping[[mapFrom]]] <- mapping[[mapTo]]
	}

	return(datasetData)

}


preProcessResample <- function(datasetData, preProcess, selectedOutcomeColumns, outcome_and_classes){
    # ==> 2 PREPROCCESING: Skewness and normalizing of the numeric predictors
    preProcessMapping <- NULL
    if(length(preProcess) > 0 ){
        transformations <- paste(preProcess, sep=",", collapse = ",")
        message <- paste0("===> INFO: Pre-processing transformation(s) (",transformations,") \r\n")
        cat(message)

        ## TODO: is corr is selected in preProcess remove it process all others and process corr last separately
        ## if ("corr" %in% preProcess && length(preProcess) > 1) {
        ##     preProcess <- preProcess[preProcess != "corr"]
        ## }

        preProcessedData <- preProcessData(datasetData, selectedOutcomeColumns, outcome_and_classes, preProcess)

        if(!is.null(preProcessedData)){
            ## Final processed data-frame
            datasetData <- preProcessedData$processedMat 

            if("pca" %in% preProcess){
                preProcessMapping <- preProcessedData$preprocessParams$rotation
                ## res.var <- factoextra::get_pca_var(res.pca)
                ## res.var$coord          # Coordinates
                ## res.var$contrib        # Contributions to the PCs
                ## res.var$cos2           # Quality of representation 
                ## corrplot::corrplot(res.var$cos2, is.corr = FALSE)
            }else if("ica" %in% preProcess){
                ## TODO not implemented
                ## preProcessMapping <- preProcessedData$processedMat
            }
        }else{
            message <- paste0("===> INFO: Could not apply preprocessing transformations, continuing without preprocessing.. \r\n")
            cat(message)
        }
    }

    return(list(preProcessMapping = preProcessMapping, datasetData = datasetData))
}
