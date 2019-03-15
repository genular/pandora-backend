#' @title create_directory
#' @description create directory recursively if directory does not exists
#' @return
create_directory <- function(path){
    ## Lets split path into vector of all recursive paths and create one by one
    parts <- unlist(strsplit(path, "/", fixed = FALSE, perl = FALSE, useBytes = FALSE))
    parts <- parts[parts != ""]

    ## Construct the vector
    paths <- c()
    i <- 1
    for (part in parts) {
        path_item <- parts[-(i:length(parts)+1 )]
        path <- paste0("/", paste(path_item, collapse = "/"))
        paths <- c(paths, path)
        i <- i +1
    }
    ## Loop paths and create directory
    for(path in unique(paths)){
        if(!dir.exists(path)){
            dir.create(path, showWarnings = FALSE, recursive = TRUE, mode = "0777")
            Sys.chmod(path, "777", use_umask = FALSE)
        }
    }
}

#' @title thisFileLocation
#' @description Returns the location of the current executing script file
#' Full file path is returned with the filename included
#' @return string
thisFileLocation <- function() {
    cmdArgs <- commandArgs(trailingOnly = FALSE)
    needle <- "--file="
    match <- grep(needle, cmdArgs)
    if (length(match) > 0) {
        return(normalizePath(sub(needle, "", cmdArgs[match])))
    } else {
        return(normalizePath(sys.frames()[[1]]$ofile))
    }
}

#' @title has_internet
#' @description Checks if there is Internet connection
#' @return boolean
has_internet <- function(){
    out <-try(is.character(RCurl::getURL("www.google.com"))) == TRUE
    return (out)
}

#' @title get_working_mode
#' @description Returns current mode of operation. So we know what file-system adapter to use
#' @return string
get_working_mode <- function(global_configuration){
    working_mode <- "remote"

    IS_DOCKER <- Sys.getenv(c("IS_DOCKER"))
    is_connected <- has_internet()

    if(IS_DOCKER != "" || is_connected == FALSE){
        working_mode <- "local"
    }else{
        if(is.null(global_configuration$storage$s3$secret) || global_configuration$storage$s3$secret == "PLACEHOLDER"){
            working_mode <- "local"
        }
    }

    return(working_mode)
}

#' @title loadRObject
#' @description Load R data file object that is saved using R "save" function
#' Create a new environment, load the .rda file into that environment, and retrieve object
#' @param file_path
#' @return object
loadRObject <- function(file_path)
{
    env <- new.env()
    nm <- load(file_path, env)[1]
    return(env[[nm]])
}
#' @title detach_package
#' @description Detaches package from R session
#' @param pkg
#' @param character.only
#' @return 
detach_package <- function(pkg, character.only = FALSE)
{
    if(!character.only)
    {
        pkg <- deparse(substitute(pkg))
    }
    search_item <- paste("package", pkg, sep = ":")
    while(search_item %in% search())
    {
       suppressWarnings(detach(search_item, unload = TRUE, character.only = TRUE, force = TRUE))
    }
}

#' @title  shortRversion
#' @description Short R version string
#' @return string
shortRversion <- function() {
   rvs <- R.Version()
   return(paste0(rvs$major,".",rvs$minor))
}

#' @title  %!in%
#' @description negation of %in% function in R
#' @return boolean
'%!in%' <- function(x,y)!('%in%'(x,y))

# encrypt the file
hp.write.aes <- function(content, filename, encryptKey) {

    contentRaw <- charToRaw(content)
    # We must add padding since total length has to be divided by 16 at the end
    contentRaw <- c(contentRaw, as.raw( rep(0, 16- length(contentRaw) %% 16) ))
    contentLength <- length(contentRaw)

    aes <- digest::AES(encryptKey, mode="ECB")
    writeBin(aes$encrypt(contentRaw), filename)

    return(contentLength)
}

# read encrypted data frame from file
hp.read.aes <- function(filename, encryptKey, contentLength) {

    dat <- readBin(filename, "raw", n=contentLength)

    aes <- digest::AES(encryptKey, mode="ECB")

    contentRaw <- aes$decrypt(dat, raw=TRUE)
    content <- rawToChar(contentRaw[contentRaw>0])
    return(content)
}  

#' @title checkCachedList
#' @description Check if R object file is already cached and loads it using
#' @param cachePath path to the cached data
#' @return boolean
checkCachedList <- function(cachePath){
    data <- NULL
    if(file.exists(cachePath)){
        data <- loadRObject(cachePath)
    }
    return(data)
}

#' @title saveCachedList
#' @description Saves object using R "save" function 
#' @param cachePath path to the cached data
#' @param data path to the cached data
#' @return boolean
saveCachedList <- function(cachePath, data){    
    save(data, file = cachePath)
}

#' @title Check if All Elements in Character Vector are Numeric
#' @description Tests, without issuing warnings, whether all elements of a character vector are legal numeric values
#' @param x
#' @param extras
#' @return boolean
all.is.numeric <- function(x, extras=c('.','NA'))
{
    x <- sub('[[:space:]]+$', '', x)
    x <- sub('^[[:space:]]+', '', x)
    xs <- x[x %!in% c('',extras)]
    if(! length(xs)) {
        return(FALSE)
    }
    return(suppressWarnings(!any(is.na(as.numeric(xs)))))
}