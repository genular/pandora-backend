#' @get /analysis/other/sam/renderOptions
pandora$handle$analysis$other$availablePackages <- expression(
    function(){
        # Get R version information
        r_version <- paste0(R.Version()$major, ".", R.Version()$minor)
        installed_packages <- rownames(installed.packages())
        data <- lapply(caret::getModelInfo(), function(x){
                            installed <- 1
                            classification <- if("Classification" %in% x$type) 1 else 0
                            regression <- if("Regression" %in% x$type) 1 else 0

                            citations <- list()
                            licenses <- list()

                            ClassProbs <- ifelse(is.null(x$prob), 0, 1)
                            VarImpMethod <- ifelse(is.null(x$varImp), 0, 1)

                            # Check if libraries are installed
                            if(!is.null(x$library) && any(!x$library %in% installed_packages)){
                                installed <- 0
                            }

                            ## For each library, gather some basic info
                            if (installed != 0){
                                for(library in x$library){
                                    lib_data <- tryCatch({
                                        citation(library)
                                    }, error = function(e) {
                                        NULL
                                    })
                                    if(!is.null(lib_data) && length(lib_data) >= 1) {
                                        lib_tmp <- unclass(lib_data)
                                        # Check if lib_tmp[[1]] exists before trying to access it
                                        if(length(lib_tmp) >= 1 && !is.null(attr(lib_tmp[[1]], "textVersion"))) {
                                            citations[[library]] <- attr(lib_tmp[[1]], "textVersion")
                                        }
                                        licenses[[library]] <- getLibraryLicense(library)
                                    }
                                }
                            }

                            return(list(
                                    label = x$label,
                                    dependencies = x$library,
                                    classification = classification,
                                    regression = regression,
                                    tags = x$tags,
                                    tuning_parameters = x$parameters,
                                    r_version = r_version,
                                    citations = citations,
                                    licenses = licenses,
                                    installed = installed
                                ))
                        })

        data[sapply(data, is.null)] <- NULL

        return(list(
            status = "success",
            data = data
        ))
    }
)
