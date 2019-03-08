#' @title  initilizeDatasetDirectory
#' @description Initialize local directories needed for temporary file saving
#' @param dataset dataset object
#' @return string
initilizeDatasetDirectory <- function(dataset){
    JOB_DIR <- paste0(DATA_PATH,"/",dataset$userID,"/tasks/",dataset$resampleID)
    ## Create JOB Directory if doesn't exist
    ifelse(!dir.exists(JOB_DIR), dir.create(JOB_DIR, recursive=TRUE), FALSE)

    output_directories  = c('plots', 'data', 'data/models', 'data/specific', 'logs')
    for (output_dir in output_directories) {
        ifelse(!dir.exists(file.path(JOB_DIR, output_dir)), dir.create(file.path(JOB_DIR, output_dir)), FALSE)
    }

    return (JOB_DIR)
}

#' @title  downloadDataset
#' @description Downloads tar.gz file extract it and return path
#' @param filepath_remote
#' @param useCache
#' @return string
downloadDataset <- function(filepath_remote, useCache = TRUE){
    filepath_gzipped <- paste0("/tmp/",basename(filepath_remote))
    
    filepath_extracted_v1 <- gsub(".tar.gz", "", filepath_gzipped)
    filepath_extracted_v2 <- paste0("/tmp/", gsub(".*_", "", filepath_extracted_v1))

    if(useCache == TRUE){
        if(file.exists(filepath_extracted_v1)){
            return (filepath_extracted_v1)
        }
        if(file.exists(filepath_extracted_v2)){
            return (filepath_extracted_v2)
        }
    }

    ## Download requested file from S3 compatible object storage
    exists <- checkFileExists(filepath_remote)
    if(exists == TRUE){
        filepath_gzipped <- downloadFile(filepath_remote, filepath_gzipped)
    }else{
        cat(paste0("===> ERROR: Cannot locate remote file: ",filepath_remote," \r\n"))
        if(file.exists(SIMON_PID)){
            invisible(file.remove(SIMON_PID))
        }
        quit()
    }
    
    if(!file.exists(filepath_gzipped)){
        cat(paste0("===> ERROR: Cannot locate download gzipped file: ",filepath_gzipped," \r\n"))
        if(file.exists(SIMON_PID)){
            invisible(file.remove(SIMON_PID))
        }
        quit()
    }else{
        untar(tarfile = filepath_gzipped, list = FALSE, exdir = "/tmp", verbose = FALSE)
        invisible(file.remove(filepath_gzipped))
    }
    
    if(!file.exists(filepath_extracted_v1)){
        filepath_extracted_v1 <- filepath_extracted_v2
        if(!file.exists(filepath_extracted_v1)){
            cat(paste0("===> ERROR: Cannot locate extracted file: ",filepath_extracted_v1," \r\n"))
            if(file.exists(SIMON_PID)){
                invisible(file.remove(SIMON_PID))
            }
            quit()
        }
    }
    
    return (filepath_extracted_v1)
}

#' @title  compressPath
#' @description Compresses file in .tar.gz format and return paths
#' @param filepath_local
#' @return list
compressPath <- function(filepath_local){
    filename <- digest::digest(basename(filepath_local), algo="md5", serialize=F)
    renamed_path = paste0(dirname(filepath_local) , "/" , filename)
    file.rename(filepath_local, renamed_path)

    gzipped_path <- paste0(renamed_path, ".tar.gz")

    try(system(paste0("tar -zcvf " , renamed_path , ".tar.gz -C " , dirname(renamed_path) , " " , basename(renamed_path)), wait = TRUE))

    return (list(
            renamed_path = renamed_path,
            gzipped_path = gzipped_path
        ))
}