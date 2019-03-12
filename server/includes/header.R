#!/usr/bin/Rscript
require(pacman)

## Variables defined in this file should be always globally accessible in any other R file/script
## This file must be always included as a start point in any other R process
p_load(config)

args <- commandArgs(TRUE)

SERVER_NAME <- args[1]
SERVER_TYPES <- c("analysis", "plots")

if(is.na(SERVER_NAME) || is.null(SERVER_NAME)){
    SERVER_NAME <- "cron"
}

simonConfig <- config::get(file = "config.yml")


if(!(SERVER_NAME %in% names(simonConfig))){
    stop("Cannot find configuration for given server name!")
}

DATA_PATH <- simonConfig[[SERVER_NAME]]$data_path
if(!dir.exists(DATA_PATH)){
    dir.create(DATA_PATH, showWarnings = FALSE, recursive = TRUE, mode = "0777")
    Sys.chmod(DATA_PATH, "777", use_umask = FALSE)
}

UPTIME_PID <- paste0(DATA_PATH,"/uptime_",SERVER_NAME,".pid")

## Load libraries that are commonly used
p_load(DBI)
p_load(pool)
p_load(urltools)

databasePool <- pool::dbPool(
        drv = RMySQL::MySQL(), ## RMySQL::MySQL() --- RMariaDB::MariaDB()
        dbname = simonConfig$database$dbname,
        host = simonConfig$database$host,
        port = simonConfig$database$port,
        username = simonConfig$database$user,
        password = simonConfig$database$password,
        maxSize = 600, 
        idleTimeout = 3600000
    )

set.seed(1337) 
 
## If warn is one, warnings are printed as they occur.
## If warn is two or larger all warnings are turned into errors.
## https://stat.ethz.ch/R-manual/R-devel/library/base/html/options.html
options(warn=1, warning.length=8170)
options(scipen=999)  # turn-off scientific notation like 1e+48

error_path <- paste0(DATA_PATH,"/error_dump_", SERVER_NAME)
options(error = quote(dump.frames(error_path, TRUE)))

source("server/includes/functions/helpers.R")
source("server/includes/functions/database.R")

## local or remote
WORKING_MODE <- get_working_mode(simonConfig)

source("server/includes/functions/file_system/main.R")

 cat(paste0("===> INFO: WORKING MODE: ",WORKING_MODE," \r\n"))

if(WORKING_MODE == "local"){
    source("server/includes/functions/file_system/adapters/local.R")
}else{
    require(aws.s3)
    source("server/includes/functions/file_system/adapters/s3.R")
}

## MAIN Route handler
simon <- list(filter = list(), handle = list(analysis = list(), general = list(), plots = list() ))

## Load Shared API Endpoints
source("server/includes/api/main.R")
source("server/includes/api/filters.R")
