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
## TODO: retry if failed
downloadDataset <- function(filepath_remote, useCache = TRUE){
    filepath_gzipped <- paste0("/tmp/",basename(filepath_remote))
    
    ## File can be saved in one of two filename versions
    ## 4daa11b0d8f8f94816925d850479f069.tar.gz
    ## e32682d2_4daa11b0d8f8f94816925d850479f069.tar.gz

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
        quit()
    }
    
    if(!file.exists(filepath_gzipped)){
        cat(paste0("===> ERROR: Cannot locate download gzipped file: ",filepath_gzipped," \r\n"))
        quit()
    }else{
        untar(tarfile = filepath_gzipped, list = FALSE, exdir = "/tmp", verbose = FALSE)
        file.remove(filepath_gzipped)
    }
    
    if(!file.exists(filepath_extracted_v1)){
        filepath_extracted_v1 <- filepath_extracted_v2
        if(!file.exists(filepath_extracted_v1)){
            cat(paste0("===> ERROR: Cannot locate extracted file: ",filepath_extracted_v1," \r\n"))
            quit()
        }
    }
    
    return (filepath_extracted_v1)
}


#' @title  Download remote file locally
#' @description Downloads an object from remote S3 filesystem
#' @param filepath_remote Full path to remote file location
#' @param filepath_local Full path to local file location. (Where to save it)
#' @return string
downloadFile <- function(filepath_remote, filepath_local){
   cat(paste0("===> INFO: file download start: ",filepath_remote," - ",filepath_local," \r\n"))
   start_time <- Sys.time()
   downloaded_path <- save_object(filepath_remote,
                         bucket = simonConfig$storage$s3$bucket,
                         file = filepath_local,
                         overwrite = TRUE,
                         check_region = FALSE,
                         key = simonConfig$storage$s3$key,
                         secret = simonConfig$storage$s3$secret,
                         accelerate = TRUE,
                         dualstack = TRUE,
                         url_style = "path",
                         base_url = simonConfig$storage$s3$endpoint,
                         region = simonConfig$storage$s3$region,
                         verbose = TRUE)
   end_time <- Sys.time()
   time_diff <- end_time - start_time
   cat(paste0("===> INFO: file download end: ",filepath_remote," time: ",time_diff," \r\n"))
   return(downloaded_path)
}

checkFileExists <- function(filepath_remote){

    cat(paste0("===> INFO: check remote exist start: ",filepath_remote," \r\n"))
    start_time <- Sys.time()
    exists <-  object_exists(filepath_remote, 
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
    cat(paste0("===> INFO: check remote exist end: ",filepath_remote," time: ",round(time_diff, digits = 2)," \r\n"))

    return(exists)
}


#' @title  Upload local file
#' @description Uploads local file object to remote S3 filesystem
#' @param user_id
#' @param filepath_local
#' @param upload_directory
#' @return string
uploadFile <- function(user_id, filepath_local, upload_directory, retry_count = 0){
    cat(paste0("===> INFO: upload file start: ",filepath_local," \r\n"))
    start_time <- Sys.time()

    filename <- basename(filepath_local)
    filepath_remote = paste0(user_id , "/" , upload_directory , "/" , filename)

    exists <- checkFileExists(filepath_remote)
    if(exists == TRUE){
        uniqueID <- as.numeric(format(Sys.time(), "%OS3")) * 1000
        uniqueIDHash <- digest::digest(basename(filepath_local), algo="crc32", serialize=F)
        filepath_remote = paste0(user_id , "/" , upload_directory , "/", uniqueIDHash , "_" , filename)
    }

    status <- put_object(filepath_local, 
                        object = filepath_remote, 
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
                        verbose = TRUE)

    end_time <- Sys.time()
    time_diff <- end_time - start_time
    cat(paste0("===> INFO: upload file end: ",filepath_local," time: ",round(time_diff, digits = 2)," \r\n"))

    ## Retry to upload file if upload failed!
    if(status != TRUE && retry_count < 5){
        cat(paste0("===> ERROR: upload file failed: ",filepath_local," status: ",status," retry_count: ",retry_count," \r\n"))
        uploadFile(user_id, filepath_local, upload_directory, retry_count + 1)
    }

    return(filepath_remote)
}

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