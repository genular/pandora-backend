#' @title  initilizeDatasetDirectory
#' @description Initialize local directories needed for temporary file saving
#' @param dataset dataset object
#' @return string
initilizeDatasetDirectory <- function(dataset){
    JOB_DIR <- paste0(TEMP_DIR,"/cron_data/",dataset$userID,"/",dataset$queueID,"/",dataset$resampleID)
  
    output_directories  = c('folds', 'models', 'data')
    for (output_dir in output_directories) {
        full_path <- file.path(JOB_DIR, output_dir)
        create_directory(full_path)
    }

    return (JOB_DIR)
}

#' @title  downloadDataset
#' @description Downloads remote tar.gz file extract it and return path
#' @param file_from users_files.file_path => "4/uploads/8d6468cae76877133d404b8ea0c68bcd.tar.gz"
#' @param useCache
#' @return string Path to the local file or FALSE if file doesn't exists
downloadDataset <- function(file_from, useCache = TRUE) {
    ## Location to temporary directory where to download files
    temp_directory <- paste0(TEMP_DIR, "/downloads")
    ## Path to the downloaded file
    file_to <- paste0(temp_directory, "/", basename(file_from))
    ## Path to the local extracted file
    file_path_local <- base::gsub(".tar.gz", "", file_to, fixed = TRUE)
    ## Extract the directory part of the file path
    dir_path <- dirname(file_path_local)
    ## Extract the file name without path, and remove part before the last underscore
    file_name_dup <- sub(".*_", "", basename(file_path_local))
    ## Reconstruct the full path with the modified file name
    file_path_local_dup <- file.path(dir_path, file_name_dup)

    if (useCache) {
        if (file.exists(file_path_local)) {
            return(file_path_local)
        }
        if (file.exists(file_path_local_dup)) {
            return(file_path_local_dup)
        }
    }

    ## Check if file exists in S3 compatible object storage
    if (!checkFileExists(file_from)) {
        cat(paste0("===> ERROR: Cannot locate remote file: ", file_from, " \r\n"))
        return(NA)  # Exit function if the file does not exist remotely
    }

    ## Download requested file
    downloadFile(file_from, file_to)
    Sys.sleep(2)

    if (!file.exists(file_to)) {
        cat(paste0("===> ERROR: Cannot locate downloaded gzipped file: ", file_to, " \r\n"))
        return(NA)
    }

    ## Extract the file
    utils::untar(tarfile = file_to, exdir = temp_directory, verbose = TRUE, tar = which_cmd("tar"))
    invisible(file.remove(file_to))  # Remove the tar file after extraction

    ## Check for extracted files existence
    if (file.exists(file_path_local)) {
        return(file_path_local)
    }
    if (file.exists(file_path_local_dup)) {
        return(file_path_local_dup)
    }

    cat(paste0("===> ERROR: Cannot locate extracted file: ", file_path_local, " nor ", file_path_local_dup, " \r\n"))
    return(NA)
}


#' @title  compressPath
#' @description Compresses file in .tar.gz format and return paths
#' @param filepath_local
#' @return gzipped_path
compressPath <- function(filepath_local){
    ## Rename file to MD5 hash of its filename
    filename <- digest::digest(basename(filepath_local), algo="md5", serialize=F)
    renamed_path = paste0(dirname(filepath_local) , "/" , filename)
    gzipped_path <- paste0(renamed_path, ".tar.gz")

    file.rename(filepath_local, renamed_path)

    try(system(paste0(which_cmd("tar"), " -zcvf " , renamed_path , ".tar.gz -C " , dirname(renamed_path) , " " , basename(renamed_path)), wait = TRUE))

    if(!file.exists(gzipped_path)){
        cat(paste0("===> ERROR: compressPath archive does not exists: ",filepath_local," => ",gzipped_path," \r\n"))
        gzipped_path <- FALSE
    }

    return (list(gzipped_path=gzipped_path, renamed_path=renamed_path))
}


saveAndUploadObject <- function(saveObject, userID, saveToPath, uploadToPath, saveObjectType, remove = TRUE){

    saveDataPaths = list(path_initial = "", renamed_path = "", gzipped_path = "", file_path = "")
    saveDataPaths$path_initial <- saveToPath

    if(saveObjectType == "RData"){
        cat(paste0("===> INFO: Saving object as Rdata file to: ",saveDataPaths$path_initial," \r\n"))
        save(saveObject, file = saveDataPaths$path_initial)
    }else{
        cat(paste0("===> INFO: Saving object as csv file to: ",saveDataPaths$path_initial," \r\n"))
        data.table::fwrite(saveObject, file = saveDataPaths$path_initial, showProgress = TRUE)
    }

    path_details = compressPath(saveDataPaths$path_initial)
    
    saveDataPaths$renamed_path = path_details$renamed_path
    saveDataPaths$gzipped_path = path_details$gzipped_path

    saveDataPaths$file_path = uploadFile(userID, saveDataPaths$gzipped_path, uploadToPath)
    
    if(remove == TRUE){
        if(file.exists(saveDataPaths$renamed_path)){ file.remove(saveDataPaths$renamed_path) }
        if(file.exists(saveDataPaths$gzipped_path)){ file.remove(saveDataPaths$gzipped_path) }
    }


    return(saveDataPaths)
}
