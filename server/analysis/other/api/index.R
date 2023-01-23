#' @get /analysis/other/sam/renderOptions
pandora$handle$analysis$other$availablePackages <- expression(
    function(){
        r_version <- shortRversion()
        data <- lapply(caret::getModelInfo(), function(x){

                            installed <- 1
                            classification <- 0
                            regression <- 0

                            citations <- list()
                            licenses <- list()

                            if("Classification" %in% x$type){
                                classification <- 1
                            }
                            if("Regression" %in% x$type){
                                regression <- 1
                            }

                            ClassProbs <- ifelse(is.null(x$prob), 0, 1)
                            VarImpMethod <- ifelse(is.null(x$varImp), 0, 1)



                            if(installed != 0 && !is.null(x$library) && x$library %!in% rownames(installed.packages())){
                                installed <- 0
                            }
                            ## For-each library gather some basic info
                            if (installed != 0){
                                for(library in x$library){
                                    lib_data <- tryCatch(citation(library),
                                        error = function(e) {
                                    })
                                    lib_tmp <- unclass(lib_data)
                                    if(is.null(citations[[library]])){
                                        citations[[library]] <-  attr(lib_tmp[[1]], "textVersion")
                                    }
                                    if(is.null(licenses[[library]])){
                                        licenses[[library]] <- getLibraryLicense(library)
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
                                    licenses = licenses,
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
