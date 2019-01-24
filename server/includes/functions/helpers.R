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

#' @title loadRObject
#' @description Load R data file object that is saved using R "save" function
#' Create a new environment, load the .rda file into that environment, and retrieve object
#' @return object
loadRObject <- function(filePath)
{
    env <- new.env()
    nm <- load(filePath, env)[1]
    return(env[[nm]])
}

detach_package <- function(pkg, character.only = FALSE)
{
    if(!character.only)
    {
        pkg <- deparse(substitute(pkg))
    }
    search_item <- paste("package", pkg, sep = ":")
    while(search_item %in% search())
    {
        detach(search_item, unload = TRUE, character.only = TRUE)
    }
}

#' @title  shortRversion
#' @description Short R version string, ("space free", useful in file/directory names. Also fine for unreleased versions of R):
#' @return string
shortRversion <- function() {
   rvs <- R.Version()
   return(paste0(rvs$major,".",rvs$minor))
}

#' @title  %!in%
#' @description Negation of %in% in R
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