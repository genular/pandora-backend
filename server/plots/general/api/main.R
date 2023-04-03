# If the URL gets called the browser will automatically download the file.
#' @serializer contentType list(type="application/octet-stream")
#' @post /plots/general/downloadSavedObject
pandora$handle$plots$general$downloadSavedObject <- expression(
    function(req, res, ...){
        args <- as.list(match.call())


        objectHash <- NULL
        if("objectHash" %in% names(args)){
            objectHash <- args$objectHash
        }

        downloadFilename <- "datasetExport"
        if("downloadFilename" %in% names(args)){
            downloadFilename <- args$downloadFilename
        }
        
        if(!is_null(objectHash)){
            
            ## .Rdata
        	tmp_path <- paste0(tempdir(check = FALSE),"/",objectHash,".Rdata")
            print(paste0("Download data from temp path: ", tmp_path, "\r\n"))

        	if(file.exists(tmp_path)){
        		res$setHeader("Content-Disposition", paste0("attachment; filename=",downloadFilename,".Rdata"))
    	  		return(readBin(tmp_path, "raw", n = file.info(tmp_path)$size))
        	}

            ## .csv
            tmp_path <- paste0(tempdir(check = FALSE),"/",objectHash,".csv")
            print(paste0("Download data from temp path: ", tmp_path, "\r\n"))

            if(file.exists(tmp_path)){
                res$setHeader("Content-Disposition", paste0("attachment; filename=",downloadFilename,".csv"))
                return(readBin(tmp_path, "raw", n = file.info(tmp_path)$size))
            }
        }
        return("File not found")
    }
)


# Get existing file path from temp folder
#' @get /plots/general/getObjectFilePath
pandora$handle$plots$general$getObjectFilePath <- expression(
    function(req, res, ...){
        args <- as.list(match.call())

        status <- TRUE

        objectHash <- NULL
        if("objectHash" %in% names(args)){
            objectHash <- args$objectHash
        }

        
        if(!is_null(objectHash)){
            ## .csv
            tmp_path <- paste0(tempdir(check = FALSE),"/",objectHash,".csv")
            print(paste0("Download data from temp path: ", tmp_path, "\r\n"))
            
            if(file.exists(tmp_path)){
                message <- tmp_path
            }else{
                status <- FALSE
                message <- FALSE
            }
        }else{
            status <- FALSE
        }

        return (list(success = status, message = message))
    }
)
