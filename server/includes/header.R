#!/usr/bin/Rscript
require(pacman)

## Variables defined in this file should be always globally accessible in any other R file/script
## This file must be always included as a start point in any other R process
p_load(config)

args <- commandArgs(TRUE)

SERVER_NAME <- args[1]
SERVER_TYPES <- c("analysis", "plots")

if(is.na(SERVER_NAME) || is.null(SERVER_NAME)){
    SERVER_NAME <- "cron_analysis"
}

pandoraConfig <- config::get(file = "config.yml")


if(!(SERVER_NAME %in% names(pandoraConfig))){
    if(SERVER_NAME != "cron_analysis"){
        stop("Cannot find configuration for given server name!")    
    }
}

TEMP_DIR <- paste0("/tmp/", pandoraConfig$salt)
UPTIME_PID <- paste0(TEMP_DIR, "/uptime_",SERVER_NAME,".pid")

## Load libraries that are commonly used
p_load(DBI)
p_load(pool)
p_load(urltools)

databasePool <- pool::dbPool(
        drv = RMySQL::MySQL(), ## RMySQL::MySQL() --- RMariaDB::MariaDB()
        dbname = pandoraConfig$database$dbname,
        host = pandoraConfig$database$host,
        port = pandoraConfig$database$port,
        username = pandoraConfig$database$user,
        password = pandoraConfig$database$password,
        maxSize = 600, 
        idleTimeout = 3600000
)

RNGkind("Mersenne-Twister")
set.seed(1337) 
 
## If warn is one, warnings are printed as they occur.
## If warn is two or larger all warnings are turned into errors.
## https://stat.ethz.ch/R-manual/R-devel/library/base/html/options.html
options(warn=1, warning.length=8170)
options(scipen=999)  # turn-off scientific notation like 1e+48
# options(error = quote(dump.frames(paste0(TEMP_DIR,"/error_dump_", SERVER_NAME), TRUE)))
options(ggrepel.max.overlaps = Inf)

Sys.setlocale("LC_ALL", "C")

source("server/includes/functions/helpers.R")
source("server/includes/functions/database.R")

create_directory(TEMP_DIR)

## local or remote
WORKING_MODE <- get_working_mode(pandoraConfig)
source("server/includes/functions/file_system/main.R")

 cat(paste0("===> INFO: WORKING MODE: ",WORKING_MODE," \r\n"))

if(WORKING_MODE == "local"){
    source("server/includes/functions/file_system/adapters/local.R")
}else{
    require(aws.s3)
    source("server/includes/functions/file_system/adapters/s3.R")
}

## MAIN Route handler
pandora <- list(filter = list(), handle = list(analysis = list(), general = list(), plots = list() ))

## Load Shared API Endpoints
source("server/includes/api/main.R")
source("server/includes/api/filters.R")
