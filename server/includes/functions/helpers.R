# Helper function to normalize scores with NA handling
#' @keywords internal
normalize <- function(x) {
    if (max(x) == min(x)) return(rep(0.5, length(x)))  # Middle ground if no range
    (x - min(x)) / (max(x) - min(x))
}

#' @title Checks process is running
#' @description Checks if we can find process by part of this name in running process list
#' @param identifier cron_analysis
#' @return vector
is_process_running <- function(identifier){
    ## Check if some other R CRON process is already running and KILL it
    process_pid <- Sys.getpid()
    process_command <- paste0("ps -ef | awk '$NF~\"",identifier,"\" {print $2}'")
    process_list <- system(process_command, intern = TRUE)
    if(length(process_list) > 0){
        process_list <- setdiff(process_list, process_pid)
    }

    return(process_list)
}

#' @title Kill process
#' @description Kills processes by PIDs
#' @param process_list numeric vector
#' @return
kill_process_pids <- function(process_list){
    if(length(process_list) > 0){
        for(cron_pid in process_list){
            print(paste0("==> Killing process SIGKILL: ", cron_pid))
            tools::pskill(as.numeric(cron_pid), signal = 9)
        }
    }
}

custom_json_serializer <- function() {
    serializer_json(
        auto_unbox = TRUE,
        null = "null",
        digits = NA,
        force = TRUE,
        POSIXt = "ISO8601"
    )
}

unbox_nested_scalars <- function(x) {
    if (is.atomic(x) && length(x) == 1) {
        attributes(x) <- NULL
        jsonlite::unbox(x)
    } else if (is.list(x)) {
        x <- lapply(x, unbox_nested_scalars)
    }
    x
}


#' @title  which_cmd
#' @description Get path to system bin file
#' @param bin_file exec name ex. tar
#' @return string
which_cmd <- function(bin_file){ 
  path <- system(paste(unname(Sys.which("which")), bin_file), TRUE)
  return(path)
}

#' @title  getExtension
#' @description Extract file extension from file path
#' @param file file path
#' @return string
getExtension <- function(file){ 
    ex <- strsplit(basename(file), split="\\.")[[1]]
    return(ex[-1])
}

#' @title calculateTimeDifference
#' @description Returns the time difference in different units
#' @param start_time Object returned from Sys.time()
#' @param unit secs or ms
#' @return numeric
calculateTimeDifference <- function(start_time, unit = "ms"){
    current_time <- Sys.time()
    time_passed <- as.numeric(ceiling(difftime(current_time, start_time,  units = c("secs"))))
    if(unit == "ms"){
        time_passed <- ceiling(time_passed * 1000)  
    }
    return (time_passed)
}

#' @title create_directory
#' @description create directory recursively if directory does not exists
#' @param path Full directory path
#' @return null
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

#' @title getLibraryLicense
#' @description Extracts the license from the R package
#' @param package Valid R installed package name
#' @return string
getLibraryLicense <- function(package){
    license1 <- packageDescription(package, fields="License")
    license2 <- ""
    ## Check if there is additional license in the LICENSE file
    if(grepl("file LICENSE", license1, fixed=TRUE) == TRUE){
      licenseFile <- system.file("LICENSE",package=package)
      if(file.exists(licenseFile)){
        license2 <- paste(readLines(licenseFile), collapse=" ")
      }
      license1 <- gsub(" + file LICENSE","",license1, fixed = TRUE)
      license1 <- gsub(" | file LICENSE","",license1, fixed = TRUE)
      license1 <- gsub(" file LICENSE","",license1, fixed = TRUE)
    }

    if(license2 != ""){
      if(nchar(license2) > 50){
        license2 <- substr(license2, start = 1, stop = 50)
        license2 <- paste(license2, "...", sep = "", collapse = NULL)
      }
      license <- paste(trimws(license1), trimws(license2), sep = " - ", collapse = NULL)
    }else{
      license <- license1
    }
    ## Merge Multiple spaces to single space
    license <- gsub("(?<=[\\s])\\s*|^\\s+|\\s+$", "", license, perl=TRUE)

    return(license)
}

#' @title getFreeMemory
#' @description
#' @param basePoint Get amount of memory in base-point - 1000 = megabytes
#' @param systemReserved How much to reserve additionally for the OS in KB
#' @return numeric
getUseableFreeMemory <- function(basePoint = 1000, systemReserved = 2000000){
    systemReserved <-  round((systemReserved  / basePoint), digits = 0)

    total_free_memory <- as.numeric(system("awk '/MemTotal/ {print $2}' /proc/meminfo", intern=TRUE))
    total_free_memory <- round((total_free_memory  / basePoint), digits = 0)

    memory_free <- (total_free_memory - systemReserved)
    return(memory_free)
}

#' @title get_working_mode
#' @description Returns current mode of operation. So we know what file-system adapter to use
#' @param global_configuration Configuration object from config.yml
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
loadRObject <- function(file_path, verbose = FALSE)
{
    # Create a new environment to load the object into
    env <- new.env(parent = emptyenv())
    
    # Attempt to load the object and capture the name of the first object loaded
    nm <- tryCatch({
        load(file_path, envir = env, verbose = verbose)
    }, error = function(e) {
        if (verbose) cat("Error loading the file:", e$message, "\n")
        return(NULL)  # Return NULL if there's an error
    })

    # Check if load was successful
    if (is.null(nm) || length(nm) == 0) {
        if (verbose) cat("No objects loaded.\n")
        return(NULL)  # Return NULL if no objects were loaded
    }

    # Return the first object loaded
    first_obj_name <- nm[1]
    if (verbose) cat("Loaded object:", first_obj_name, "\n")
    return(env[[first_obj_name]])
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

#' @title hp.read.aes
#' @description read encrypted data frame from file
#' @return string
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
saveCachedList <- function(cachePath, data, type = "Rdata"){
    if (file.exists(cachePath)) {
        # Delete file if it exists
        file.remove(cachePath)
    }
    
    if(type == "Rdata"){
        save(data, file = cachePath)
    }else if(type == "csv"){
        write.csv(data, file = cachePath, row.names = FALSE)
    }else{
        save(data, file = cachePath)
    }
    # Set global permissions 
    Sys.chmod(tempdir(), mode = "777")
    Sys.chmod(cachePath, mode = "777")
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

#' @title Round dataframe
#' @description Round only numeric dataframe
#' @param x
#' @param extras
#' @return boolean
round_df <- function(df, digits) {
  nums <- vapply(df, is.numeric, FUN.VALUE = logical(1))
  df[,nums] <- round(df[,nums], digits = digits)
  return(df)
}

#' @title Prints data to variable
#' @description Prints data to variable
#' @param R data
#' @return text
convertToString <- function(inputData){
    width <- getOption("width")
    digits <- getOption("digits")

    options(width = 500)
    options(digits = 10)

    text_output <- R.utils::captureOutput(print(inputData, width = 500, digits = 10))
    text_output <- paste(text_output, collapse="\n")
    text_output <- toString(RCurl::base64Encode(text_output, "txt"))

    options(width = width)
    options(digits = digits)

    return(text_output)
}

#' @title Check if request variable is Empty
#' @description Checks if the given variable is empty and optionally logs the variable name.
#' @param variable The variable to check.
#' @param variable_name Optional; the name of the variable to log.
#' @return boolean TRUE if the variable is considered empty, FALSE otherwise.
is_var_empty <- function(variable, variable_name = NULL){
    # Initialize is_empty as FALSE
    is_empty <- FALSE
    
    # Check for different conditions that qualify the variable as empty
    if(length(variable) == 0 || rlang::is_null(variable)){
        is_empty <- TRUE
    } else if (is.character(variable) && length(variable) == 1 && variable == "") {
        is_empty <- TRUE
    } else if (rlang::is_empty(variable)) {
        is_empty <- TRUE
    }

    # Optionally print variable name
    if (!is.null(variable_name)) {
        print(paste0("=====> INFO: Variable '", variable_name, "' is_empty: ", is_empty))
    }
    
    return(is_empty)
}


getPreviouslySavedResponse <- function(plot_unique_hash, response_data, check_count){
    tmp_dir <- tempdir(check = TRUE)
    tmp_check_count <- 0
    for (name in names(plot_unique_hash)) {
        cachedFiles <- list.files(tmp_dir, full.names = TRUE, pattern=paste0(plot_unique_hash[[name]], ".*")) 
        for(cachedFile in cachedFiles){
            cachedFileExtension <- tools::file_ext(cachedFile)
            ## Check if some files where found in tmpdir that match our unique hash
            if(identical(cachedFile, character(0)) == FALSE){
                if(file.exists(cachedFile) == TRUE){
                    if(cachedFileExtension == "svg"){
                        raw_file <- readBin(cachedFile, "raw", n = file.info(cachedFile)$size)
                        encoded_file <- RCurl::base64Encode(raw_file, "txt")
                        response_data[[name]] = as.character(encoded_file) 
                    }else if(cachedFileExtension == "png"){
                        raw_file <- readBin(cachedFile, "raw", n = file.info(cachedFile)$size)
                        encoded_file <- RCurl::base64Encode(raw_file, "txt")
                        response_data[[paste0(name, "_png")]] = as.character(encoded_file)
                    }else if(cachedFileExtension == "Rdata"){
                        response_data[[name]] = substr(basename(cachedFile), 1, nchar(basename(cachedFile))-6)
                    }else if(cachedFileExtension == "RDS"){
                        response_data[[name]] = loadRObject(cachedFile)
                    }
                    tmp_check_count <- tmp_check_count + 1
                }
            }
        }
    }
    if(tmp_check_count == check_count){
        return (list(success = TRUE, message = response_data))
    }else{
        return(FALSE)
    }
}

#' @title Execute command
#' @description Executes command in system with timeout, If unsuccessful FALSE is returned otherwise command output
#' @param cmd_string
#' @param time_out
#' @return boolean
executeSystemCommand <- function(cmd_string, time_out = 300){
    input_args <- list(
        cmd_string,
        timeout=time_out
    )

    cmd_out <- FALSE
    cmd_out_status <- FALSE

    process.execution <- tryCatch( garbage <- R.utils::captureOutput(cmd_out <- R.utils::withTimeout(
        do.call(system, input_args), 
        timeout=time_out - 2, 
        onTimeout = "error") ), 
        error = function(e){ return(e) } )

    options(warn = -1)
    if(!inherits(process.execution, "error") && !inherits(cmd_out, 'try-error')){
        cmd_out_status <- TRUE
    }else{
        if(inherits(cmd_out, 'try-error')){
            message <- base::geterrmessage()
            process.execution$message <- message
        }
        cmd_out <- process.execution$message
    }

    if(cmd_out != FALSE){
        print(cmd_out)
    }

    # Restore default warning reporting
    options(warn=0)
    return(cmd_out_status)
}

convertSVGtoPNG <- function(tmp_path) {
    tmp_path_png <- stringr::str_replace(tmp_path, ".svg", ".png")
    command <- paste0(which_cmd("rsvg-convert"), " ", tmp_path, " -f png --dpi-x 300 --dpi-y 300 -o ", tmp_path_png)
    
    png_data <- tryCatch({
        # Execute command and check output
        cmd_out <- executeSystemCommand(command, 1000)
        
        if (cmd_out == FALSE) {
            stop("SVG conversion command failed.")
        }
        
        # Read and encode the PNG data if command succeeds
        as.character(RCurl::base64Encode(readBin(tmp_path_png, "raw", n = file.info(tmp_path_png)$size), "txt"))
        
    }, error = function(e) {
        # Log error if desired
        message("==> Error during SVG to PNG conversion: ", e$message)
        NULL  # Return NULL if any error occurs
    }, warning = function(w) {
        # Log warning if desired
        message("==> Warning during SVG to PNG conversion: ", w$message)
        NULL  # Return NULL if any warning occurs
    })
    
    return(png_data)
}

## This function is used to generated SVG string from path
## TODO: optimize SVG using svgo package
optimizeSVGFile <- function(tmp_path){

    size_bytes <- file.info(tmp_path)$size
    size_mb <- ceiling(size_bytes / 1000000)

    # Read the raw data from the file
    svg_raw <- readBin(tmp_path, "raw", n = size_bytes)

    # Base64 encode the raw data
    svg_encoded <- RCurl::base64Encode(svg_raw, "txt")

    # Convert to character string and remove any attributes
    svg_data <- as.character(svg_encoded)
    attributes(svg_data) <- NULL  # Remove all attributes

    if(size_mb < 100){
        return(svg_data)
    } else {
        # TODO:
        # Image is too big; serve it as a file for download
        return(FALSE)
    }

    ## command <- paste0(which_cmd("svgo")," ",tmp_path," -o ",tmp_path)
    ## cmd_out <- executeSystemCommand(command, 300)
    ## if(cmd_out == FALSE){
    ##     svg_data <- FALSE
    ## }else{
    ##     svg_data <- as.character(RCurl::base64Encode(readBin(tmp_path, "raw", n = file.info(tmp_path)$size), "txt")) 
    ## }
    ## return(svg_data)
}

processTimeout <- function(expr, envir = parent.frame(), timeout, onTimeout=c("error", "warning", "silent")) {
    # substitute expression so it is not executed as soon it is used
    expr <- substitute(expr)
    # match on_timeout
    onTimeout <- match.arg(onTimeout)
    # execute expr in separate fork
    myfork <- parallel::mcparallel({
        eval(expr, envir = envir)
    }, silent = FALSE)

    # wait max n seconds for a result.
    myresult <- parallel::mccollect(myfork, wait = FALSE, timeout = timeout)
    # kill fork after collect has returned
    tools::pskill(myfork$pid, tools::SIGKILL)
    tools::pskill(-1 * myfork$pid, tools::SIGKILL)

    # clean up:
    parallel::mccollect(myfork, wait = FALSE)

    # timeout?
    if (is.null(myresult)) {
        if (onTimeout == "error") {
            stop("reached elapsed time limit")
        } else if (onTimeout == "warning") {
            warning("reached elapsed time limit")
        } else if (onTimeout == "silent") {
            myresult <- NA
        }
    }
    # move this to distinguish between timeout and NULL returns
    myresult <- myresult[[1]]
    if ("try-error" %in% class(myresult)) {
        stop(attr(myresult, "condition"))
    }
    # send the buffered response
    return(myresult)
}

#' @title loadDataFromFileSystem
#' @description Load dataset CSV file from filesystem
#' @param selectedFilePath string
#' @param header boolean
#' @param sep string
#' @param stringsAsFactors boolean
#' @param data.table boolean
#' @param retype boolean
#' @return dataframe
loadDataFromFileSystem <- function(selectedFilePath, header = T, sep = ',', stringsAsFactors = FALSE, data.table = FALSE, retype = TRUE){

    dataset <- data.table::fread(selectedFilePath, header = header, sep = sep, stringsAsFactors = stringsAsFactors, 
        data.table = data.table)
    
    # remove any extra spaces in character column values
    dataset <- dataset %>% dplyr::mutate(across(where(is.character), stringr::str_trim))

    # auto-detect column types
    if(retype == TRUE){
        print("Retyping columns (loadDataFromFileSystem)")
        dataset <- dataset %>% hablar::retype()
        dataset <- convert_to_numeric(dataset)
    }

    return(dataset)
}

#' @title convert_to_numeric 
#' @description It then calculates the percentage of numeric values (`num_perc`) by dividing `num_count` by the total length of the column. 
## If `num_perc` is greater than 10%, the column is converted to numeric using `as.numeric()` and the original data frame is modified. 
convert_to_numeric <- function(data) {
  # Validate input
    if (!is.data.frame(data)) {
        print(paste0("=====> ERROR: The input 'data' must be a dataframe."))
        return(dataset)
    }

    # Loop over columns
    for (col in names(data)) {
        # Only convert if column is not already numeric
        if (!is.numeric(data[[col]])) {
            # Attempt to convert to numeric and suppress warnings
            numeric_attempt <- suppressWarnings(as.numeric(data[[col]]))

            # Count number of successfully converted numeric values
            num_count <- sum(!is.na(numeric_attempt))

            # Calculate percentage of numeric values
            num_perc <- num_count / length(data[[col]])

            # Convert column to numeric if more than 10% is numeric
            if (num_perc > 0.10) {
                cat("=====> INFO: Converting column '", col, "' to numeric. Percentage of numeric values: ", num_perc * 100, "%\n", sep="")
                # Use the already converted values to avoid re-conversion
                data[[col]] <- numeric_attempt
            }
        }
    }

    return(data)
}


#' @title castAllStringsToNA   
#' @description Removes all strings/words from specified columns in dataset
#' @param dataset dataframe
#' @param excludeColumns character
#' @return dataframe
castAllStringsToNA <- function(dataset, excludeColumns = c()) {
    # Validate inputs
    if (!is.data.frame(dataset))  {
        stop("=====> ERROR: The 'dataset' must be a dataframe.")
    }

    if (!is.character(excludeColumns)) {
        stop("=====> ERROR: castAllStringsToNA The 'excludeColumns' must be a character vector.")
    }
    
    # Identify columns to process
    includedColumns <- setdiff(names(dataset), excludeColumns)

    # Process each included column
    dataset[includedColumns] <- lapply(dataset[includedColumns], function(column) {
        if (is.factor(column)) {
            column <- as.character(column)
        }
        if (is.character(column)) {
            # Convert all non-numeric strings to NA
            suppressWarnings(as.numeric(column))
        } else {
            # Leave columns of other types unchanged
            column
        }
    })

    # Return the modified dataset
    return(dataset)
}


safe_access <- function(data, ...) {
  elements <- list(...)
  for(element in elements) {
    if(is.null(data[[element]])) {
      return(FALSE) # Returns FALSE immediately if any element does not exist
    } else {
      data <- data[[element]]
    }
  }
  return(TRUE) # Returns TRUE if all elements exist
}
