#' @title  downloadFile
#' @description Download / copy file from one path to another
#' @param file_path_from Full path to remote file location
#' @param file_path_to Full path to local file location. (Where to save it)
#' @return string
downloadFile <- function(file_path_from, file_path_to){
    file_path_from <- file.path(simonConfig$backend$data_path, file_path_from)
    cat(paste0("===> INFO: downloadFile: ",file_path_from," \r\n"))
    
     ## Create directory if doesn't exist
    ifelse(!dir.exists(dirname(file_path_to)), dir.create(dirname(file_path_to), recursive=TRUE), FALSE)

    # copy the files to the new folder
    file.copy(file_path_from, file_path_to)

    return(file_path_to)
}

#' @title  checkFileExists
#' @description Checks if file on the path exist or not
#' @param file_path
#' @return boolean
checkFileExists <- function(file_path){
    file_path <- file.path(simonConfig$backend$data_path, file_path)
    cat(paste0("===> INFO: checkFileExists: ",checkFileExists," \r\n"))
    
    exists <- FALSE
    if(file.exists(file_path)){
        exists <- TRUE
    }
    return(exists)
}


#' @title  uploadFile
#' @description Saves / Uploads file from one location to another
#' @param user_id
#' @param filepath_local
#' @param upload_directory
#' @return string
uploadFile <- function(user_id, filepath_local, upload_directory, retry_count = 0){
    cat(paste0("===> INFO: upload file start: ",filepath_local," \r\n"))

    filename <- basename(filepath_local)
    filepath_remote = paste0(user_id , "/" , upload_directory , "/" , filename)

    exists <- checkFileExists(filepath_remote)
    if(exists == TRUE){
        uniqueID <- as.numeric(format(Sys.time(), "%OS3")) * 1000
        uniqueIDHash <- digest::digest(basename(filepath_local), algo="crc32", serialize=F)
        filepath_remote = paste0(user_id , "/" , upload_directory , "/", uniqueIDHash , "_" , filename)
    }
    filepath_remote <- file.path(simonConfig$backend$data_path, filepath_remote)

     ## Create directory if doesn't exist
    ifelse(!dir.exists(dirname(filepath_remote)), dir.create(dirname(filepath_remote), recursive=TRUE), FALSE)

    file.copy(filepath_local, filepath_remote)

    return(filepath_remote)
}
