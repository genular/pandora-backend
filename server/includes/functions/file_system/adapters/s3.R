#' @title  downloadFile
#' @description Download / copy file from one path to another
#' @param file_path_from Full path to remote file location
#' @param file_path_to Full path to local file location. (Where to save it)
#' @return string
downloadFile <- function(file_path_from, file_path_to){
   cat(paste0("===> INFO: file download start: ",file_path_from," - ",file_path_to," \r\n"))

    file_path_to_basedir <- dirname(file_path_to)
     ## Create directory if doesn't exist
    if(!dir.exists(file_path_to_basedir)){
        dir.create(file_path_to_basedir, showWarnings = FALSE, recursive = TRUE, mode = "0777")
        Sys.chmod(file_path_to_basedir, "777", use_umask = FALSE)
    }

    downloaded_path <- save_object(file_path_from,
                         bucket = simonConfig$storage$s3$bucket,
                         file = file_path_to,
                         overwrite = TRUE,
                         check_region = FALSE,
                         key = simonConfig$storage$s3$key,
                         secret = simonConfig$storage$s3$secret,
                         accelerate = TRUE,
                         dualstack = TRUE,
                         url_style = "path",
                         base_url = simonConfig$storage$s3$endpoint,
                         region = simonConfig$storage$s3$region,
                         verbose = FALSE)

   cat(paste0("===> INFO: file download end: ",downloaded_path," \r\n"))
   return(downloaded_path)
}

#' @title  checkFileExists
#' @description Checks if file on the path exist or not
#' @param file_path
#' @return boolean
checkFileExists <- function(file_path){

    cat(paste0("===> INFO: check remote exist start: ",file_path," \r\n"))
    start_time <- Sys.time()
    exists <-  object_exists(file_path, 
                         bucket = simonConfig$storage$s3$bucket,
                         check_region = FALSE,
                         key = simonConfig$storage$s3$key,
                         secret = simonConfig$storage$s3$secret,
                         accelerate = TRUE,
                         dualstack = TRUE,
                         url_style = "path",
                         base_url = simonConfig$storage$s3$endpoint,
                         region = simonConfig$storage$s3$region,
                         verbose = FALSE
                         )
    end_time <- Sys.time()
    time_diff <- end_time - start_time
    cat(paste0("===> INFO: check remote exist end: ",file_path," time: ",round(time_diff, digits = 2)," \r\n"))

    return(exists)
}


#' @title  Upload local file
#' @description Uploads local file object to remote S3 filesystem
#' @param user_id
#' @param file_from Full path to the local file-system file
#' @param upload_directory
#' @return string
uploadFile <- function(user_id, file_from, upload_directory, retry_count = 0){
    cat(paste0("===> INFO: upload file start from: ",file_from," \r\n"))
    start_time <- Sys.time()

    filename <- basename(file_from)
    file_to = paste0(user_id , "/" , upload_directory , "/" , filename)

    exists <- checkFileExists(file_to)
    if(exists == TRUE){
        uniqueID <- as.numeric(format(Sys.time(), "%OS3")) * 1000
        uniqueIDHash <- digest::digest(filename, algo="crc32", serialize=F)
        file_to = paste0(user_id , "/" , upload_directory , "/", uniqueIDHash , "_" , filename)
    }
    ## Lets make actual upload
    status <- put_object(file_from, 
                        object = file_to, 
                        bucket = simonConfig$storage$s3$bucket,
                        multipart = TRUE,
                        show_progress = FALSE,
                        check_region = FALSE,
                        key = simonConfig$storage$s3$key,
                        secret = simonConfig$storage$s3$secret,
                        accelerate = TRUE,
                        dualstack = TRUE,
                        url_style = "path",
                        base_url = simonConfig$storage$s3$endpoint,
                        region = simonConfig$storage$s3$region,
                        verbose = FALSE)

    end_time <- Sys.time()
    time_diff <- end_time - start_time
    cat(paste0("===> INFO: upload file end: ",file_from," time: ",round(time_diff, digits = 2)," \r\n"))

    ## Retry to upload file if upload failed!
    if(status != TRUE && retry_count < 5){
        cat(paste0("===> ERROR: upload file failed: ",file_from," status: ",status," retry_count: ",retry_count," \r\n"))
        uploadFile(user_id, file_from, upload_directory, retry_count + 1)
    }

    return(file_to)
}
