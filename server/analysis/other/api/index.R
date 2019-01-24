#' @get /analysis/other/sam/renderOptions
simon$handle$analysis$other$availablePackages <- expression(
    function(){
        r_version <- shortRversion()
        data <- lapply(caret::getModelInfo(), function(x){

                            installed <- 1
                            classification <- 0
                            regression <- 0
                            citations <- list()

                            if("Classification" %in% x$type){
                                classification <- 1
                            }
                            if("Regression" %in% x$type){
                                regression <- 1
                            }


                            if(installed != 0 && !is.null(x$library) && x$library %!in% rownames(installed.packages())){
                                installed <- 0
                            }

                               if (installed != 0){
                                for(library in x$library){
                                    lib_data <- tryCatch(citation(library),
                                        error = function(e) {
                                    })
                                    lib_tmp <- unclass(lib_data)
                                    if(is.null(citations[[library]])){
                                        citations[[library]] <-  attr(lib_tmp[[1]], "textVersion")
                                    }
                                }
                            }

                            return(list(
                                    label = x$label,
                                    dependencies = x$library,
                                    classification = classification,
                                    regression = regression,
                                    tags = c(x$tags),
                                    tuning_parameters = c(x$parameters),
                                    r_version = r_version,
                                    citations = citations,
                                    installed = installed
                                ))
                        }
                    )

        data[sapply(data, is.null)] <- NULL
    
        return(list(
            status = "success",
            data = data
        ))
    }
)