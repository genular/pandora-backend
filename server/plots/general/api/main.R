# If the URL gets called the browser will automatically download the file.
#' @serializer contentType list(type="application/octet-stream")
#' @post /plots/general/downloadSavedObject
simon$handle$plots$general$downloadSavedObject <- expression(
    function(req, res, ...){
        args <- as.list(match.call())


        objectHash <- NULL
        if("objectHash" %in% names(args)){
            objectHash <- args$objectHash
        }
        print(objectHash)
        if(!is_null(objectHash)){
        	tmp_path <- paste0(tempdir(check = FALSE),"/",objectHash,".Rdata")
        	print(tmp_path)

        	if(file.exists(tmp_path)){
        		res$setHeader("Content-Disposition", "attachment; filename=processingData.Rdata")
    	  		return(readBin(tmp_path, "raw", n = file.info(tmp_path)$size))
        	}else{
        		print("File doesn't exists")
        	}
        }

        return (list("File not found"))
    }
)
