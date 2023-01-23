#' @title  downloadFile
#' @description Download / copy file from one path to another
#' @param file_path_from Full path to remote file location
#' @param file_path_to Full path to local file location. (Where to save it)
#' @return string
downloadFile <- function(file_path_from, file_path_to){
    cat(paste0("===> INFO: file download start: ",file_path_from," - ",file_path_to," \r\n"))
    
    file_path_from_basedir <- dirname(file_path_to)
    create_directory(file_path_from_basedir)

    # copy the files to the new folder
    file.copy(file.path(pandoraConfig$storage$local$data_path, file_path_from), file_path_to)

    return(file_path_to)
}

#' @title  checkFileExists
#' @description Checks if file on the path exist or not
#' @param file_path
#' @return boolean
checkFileExists <- function(file_path){
    file_path <- file.path(pandoraConfig$storage$local$data_path, file_path)

    cat(paste0("===> INFO: checkFileExists: ",file_path," \r\n"))
    exists <- FALSE
    if(file.exists(file_path)){
        exists <- TRUE
    }
    return(exists)
}


#' @title  uploadFile
#' @description Saves / Uploads file from one location to another
#' @param user_id
#' @param file_from Full path to the local file-system file
#' @param upload_directory example: "analysis/",serverData$queueID,"/",resampleID
#' @return string
uploadFile <- function(user_id, file_from, upload_directory, retry_count = 0){

    filename <- basename(file_from)
    file_to = paste0("users/",user_id , "/" , upload_directory , "/" , filename)

    cat(paste0("===> INFO: upload file start: ",file_from," - ",file.path(pandoraConfig$storage$local$data_path, file_to)," \r\n"))

    exists <- checkFileExists(file_to)
    if(exists == TRUE){
        uniqueID <- as.numeric(format(Sys.time(), "%OS3")) * 1000
        uniqueIDHash <- digest::digest(filename, algo="crc32", serialize=F)
        file_to = paste0("users/",user_id , "/" , upload_directory , "/", uniqueIDHash , "_" , filename)
    }
    
    local_file_to <- file.path(pandoraConfig$storage$local$data_path, file_to)
    local_file_basedir <- dirname(local_file_to)
    create_directory(local_file_basedir)

    file.copy(file_from, local_file_to)

    return(file_to)
}
