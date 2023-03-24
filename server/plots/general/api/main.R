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

        print(objectHash)
        
        if(!is_null(objectHash)){
            
            ## .Rdata
        	tmp_path <- paste0(tempdir(check = FALSE),"/",objectHash,".Rdata")
        	if(file.exists(tmp_path)){
        		res$setHeader("Content-Disposition", paste0("attachment; filename=",downloadFilename,".Rdata"))
    	  		return(readBin(tmp_path, "raw", n = file.info(tmp_path)$size))
        	}

            ## .csv
            tmp_path <- paste0(tempdir(check = FALSE),"/",objectHash,".csv")
            if(file.exists(tmp_path)){
                res$setHeader("Content-Disposition", paste0("attachment; filename=",downloadFilename,".csv"))
                return(readBin(tmp_path, "raw", n = file.info(tmp_path)$size))
            }
        }
        return("File not found")
    }
)
