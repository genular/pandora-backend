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
#' @description Downloads remote tar.gz file extract it and return path
#' @param filepath_remote
#' @param useCache
#' @return string Path to the local file or FALSE if file doesn't exists
downloadDataset <- function(filepath_remote, useCache = TRUE){
    file_exist <- TRUE
    filepath_gzipped <- paste0("/tmp/",basename(filepath_remote))
    
    ## Path to the local file
    file_path_local <- gsub(".tar.gz", "", filepath_gzipped)
    ## in case of duplicated name on uploading also check for this one
    file_path_local_dup <- paste0("/tmp/", gsub(".*_", "", file_path_local))

    if(useCache == TRUE){
        if(file.exists(file_path_local)){
            return (file_path_local)
        }
        if(file.exists(file_path_local_dup)){
            return (file_path_local_dup)
        }
    }

    ## Download requested file from S3 compatible object storage
    exists <- checkFileExists(filepath_remote)
    if(exists == TRUE){
        filepath_gzipped <- downloadFile(filepath_remote, filepath_gzipped)
    }else{
        cat(paste0("===> ERROR: Cannot locate remote file: ",filepath_remote," \r\n"))
        file_exist <- FALSE
    }
    
    if(!file.exists(filepath_gzipped)){
        cat(paste0("===> ERROR: Cannot locate download gzipped file: ",filepath_gzipped," \r\n"))
        file_exist <- FALSE
    }else{
        untar(tarfile = filepath_gzipped, list = FALSE, exdir = "/tmp", verbose = FALSE)
        invisible(file.remove(filepath_gzipped))
    }
    
    if(!file.exists(file_path_local)){
        file_path_local <- file_path_local_dup
        if(!file.exists(file_path_local)){
            cat(paste0("===> ERROR: Cannot locate extracted file: ",file_path_local," \r\n"))
            file_exist <- FALSE
        }
    }

    if(file_exist == FALSE){
        file_path_local <- file_exist
    }
    
    return (file_path_local)
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