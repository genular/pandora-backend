plot_tableplot = function(dataset, settings, fileHeader){
    results <- list(status = FALSE, data = NULL)

    names(dataset) <- plyr::mapvalues(names(dataset), from=fileHeader$remapped, to=fileHeader$original)
    input_args <- list(dataset, fontsize = settings$fontSize)

    model.execution <- tryCatch( garbage <- R.utils::captureOutput(results$data <- R.utils::withTimeout(do.call(tabplot::tableplot, input_args), timeout=10000, onTimeout = "error") ), error = function(e){ return(e) } )

    options(warn = -1)
    if(!inherits(model.execution, "error") && !inherits(results$data, 'try-error') && !is.null(results$data)){
        results$status = TRUE
    }else{
        if(inherits(results$data, 'try-error')){
            message <- base::geterrmessage()
            model.execution$message <- message
        }
        results$data <- model.execution$message
    }
    # Restore default warning reporting
    options(warn=0)

    return(results)
}

save_tableplot = function(plot_data, path, settings){
    results <- list(status = FALSE, data = NULL)
    input_args <- list(plot_data, filename=path, width = 12 * settings$aspect_ratio, height = 12, onePage = TRUE)

    model.execution <- tryCatch( garbage <- R.utils::captureOutput(results$data <- R.utils::withTimeout(do.call(tabplot::tableSave, input_args), timeout=10000, onTimeout = "error") ), error = function(e){ return(e) } )
    options(warn = -1)
    if(!inherits(model.execution, "error") && !inherits(results$data, 'try-error')){
        results$status = TRUE
    }else{
        if(inherits(results$data, 'try-error')){
            message <- base::geterrmessage()
            model.execution$message <- message
        }
        results$data <- TRUE
    }
    # Restore default warning reporting
    options(warn=0)
    return(results)
}

plot_matrix_plot = function(dataset, settings, fileHeader){

    print("Generating plot_matrix_plot")

    if(length(settings$selectedColumns) > 5){
        ## Limit selected columns to 5
        settings$selectedColumns <- tail(settings$selectedColumns, n=5)
    }

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    if(!is.null(settings$groupingVariable)){
        print("Generating plot_matrix_plot grouped")
        ## Limit groupingVariable to 1
        settings$groupingVariable <- tail(settings$groupingVariable, n=1)
        groupingVariableOriginal <- fileHeader %>% filter(remapped %in% settings$groupingVariable)
        groupingVariableOriginal <- groupingVariableOriginal$original

        plot_dataset <- dataset %>% 
                    #select(responder, starts_with("tcell_elispot")) %>%
                    #filter(disease_severity == "severe") %>% 
                    select_if(~sum(!is.na(.)) > 0) %>% 
                    select(any_of(c(settings$selectedColumns, settings$groupingVariable)))

        names(plot_dataset) <- plyr::mapvalues(names(plot_dataset), from=fileHeader$remapped, to=fileHeader$original)

        renderedPlot <- plot_dataset %>% GGally::ggpairs(., 
                            title = paste0("Correlation matrix by ", groupingVariableOriginal), 
                            mapping = ggplot2::aes_string(colour=groupingVariableOriginal), 
                            lower = list(continuous = GGally::wrap("smooth", alpha = 0.3, size=0.1), discrete = "blank", combo="blank"),
                            diag = list(discrete="barDiag", continuous = GGally::wrap("densityDiag", alpha=0.5)), 
                            upper = list(combo = GGally::wrap("box_no_facet", alpha=0.5)))
    }else{
        print("Generating plot_matrix_plot single")

        # Ensure dataset is a data frame
        plot_dataset <- as.data.frame(dataset)

        # Filter selected columns to those that exist in the dataset
        valid_columns <- settings$selectedColumns[settings$selectedColumns %in% colnames(plot_dataset)]
        if (length(valid_columns) < 2) {
            print("No valid columns found in dataset to generate the plot. Ensure at least two columns are selected.")
            renderedPlot <- NULL
        }else{
            renderedPlot <- TRUE
        }

        if(!is.null(renderedPlot)){
            # Select the validated columns and drop rows with NAs
            plot_dataset <- plot_dataset %>%
                select(any_of(valid_columns)) %>%
                drop_na()

            # Map column names from `remapped` to `original` in `fileHeader`, only for existing columns
            existing_mapped_columns <- valid_columns[valid_columns %in% fileHeader$remapped]
            plot_dataset <- plot_dataset %>%
                rename_with(~ plyr::mapvalues(.x, from = fileHeader$remapped, to = fileHeader$original, warn_missing = FALSE), .cols = existing_mapped_columns)

            # Generate the correlation matrix plot if we have at least two columns
            if (ncol(plot_dataset) >= 2) {
                renderedPlot <- GGally::ggpairs(
                    plot_dataset, 
                    title = "Correlation matrix",
                    lower = list(
                        continuous = GGally::wrap("smooth", alpha = 0.3, size = 0.1), 
                        discrete = "blank", 
                        combo = "blank"
                    ),
                    diag = list(
                        discrete = "barDiag", 
                        continuous = GGally::wrap("densityDiag", alpha = 0.5)
                    ), 
                    upper = list(combo = GGally::wrap("box_no_facet", alpha = 0.5))
                )
                print("Plot generated successfully.")
            } else {
                print("Insufficient columns for plotting. At least two columns are required for a correlation matrix.")
            }
        }

    }

    if(!is.null(renderedPlot)){
        renderedPlot <- renderedPlot + scale_fill_brewer(palette=settings$colorPalette) + 
                theme(text=element_text(size=settings$fontSize), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank())
    }

    return(renderedPlot)
}
