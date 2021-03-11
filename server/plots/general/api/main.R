#* Downloads existing file
#* @serializer contentType list(type='image/png')
#' @post /plots/general/downloadObject
simon$handle$plots$general$downloadObject <- expression(
    function(req, res, ...){
        args <- as.list(match.call())


        selectedFileID <- 0
        if("selectedFileID" %in% names(args)){
            selectedFileID <- as.numeric(args$selectedFileID)
        }


        return (list(success = TRUE, message = FALSE))
    }
)
