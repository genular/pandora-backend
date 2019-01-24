#!/usr/bin/Rscript

## Variables defined in this file should be always globally accessible in any other R file/script
## This file must be always included as a start point in any other R process
library(config)
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
ifelse(!dir.exists(DATA_PATH), dir.create(DATA_PATH), FALSE)

UPTIME_PID <- paste0(DATA_PATH,"/uptime_",SERVER_NAME,".pid")

## Load libraries that are commonly used
library(DBI)
library(pool)

library(urltools)

## TODO: this is so SLOW! Preload AWS client to speed up process
library(aws.s3)

databasePool <- pool::dbPool(
        drv = RMariaDB::MariaDB(), ## RMySQL::MySQL() --- RMariaDB::MariaDB()
        dbname = simonConfig[[SERVER_NAME]]$database$dbname,
        host = simonConfig[[SERVER_NAME]]$database$host,
        port = simonConfig[[SERVER_NAME]]$database$port,
        username = simonConfig[[SERVER_NAME]]$database$user,
        password = simonConfig[[SERVER_NAME]]$database$password,
        maxSize = 600, 
        idleTimeout = 3600000
    )

set.seed(1337) 
 
## If warn is one, warnings are printed as they occur.
## If warn is two or larger all warnings are turned into errors.
## https://stat.ethz.ch/R-manual/R-devel/library/base/html/options.html
options(warn=1, warning.length=8170)
error_path <- paste0(DATA_PATH,"/error_dump_", SERVER_NAME)
options(error = quote(dump.frames(error_path, TRUE)))

source("server/includes/functions/helpers.R")
source("server/includes/functions/database.R")
source("server/includes/functions/fileSystem.R")

## MAIN Route handler
simon <- list(filter = list(), handle = list(analysis = list(), general = list(), plots = list() ))

## Load Shared API Endpoints
source("server/includes/api/main.R")
source("server/includes/api/filters.R")
