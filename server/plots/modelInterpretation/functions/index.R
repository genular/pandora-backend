sanitize_filename <- function(name) {
    # Trim leading and trailing whitespace
    trimmed_name = trimws(name)
    
    # Replace slashes with underscore
    sanitized = gsub("/", "_", trimmed_name)
    
    # Replace backticks with nothing
    sanitized = gsub("`", "", sanitized)
    
    # Replace all remaining whitespace characters (spaces, tabs, new lines, etc.) with underscores
    sanitized = gsub("\\s+", "_", sanitized)
    
    return(sanitized)
}



plot_interpretation_scatter <- function(pdp_data, original_feature_name, original_outcome_name, settings, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    plotData <- ggplot(pdp_data, aes_string(x = sprintf("`%s`", original_feature_name), y = "yhat")) +
        geom_point(alpha = 0.5) +
        geom_smooth(method = "loess", se = FALSE) +
        labs(title = paste("Scatter and Smoothed Trends of", sprintf("`%s`", original_feature_name), "on", original_outcome_name, "Prediction"),
             x = sprintf("`%s`", original_feature_name), y = "Average Predicted Probability") +
        theme_minimal() +
        theme(legend.title = element_blank())

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

plot_interpretation_heatmap <- function(pd_interaction, original_name1, original_name2, settings, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))
    
    plotData <- ggplot(pd_interaction, aes_string(x = original_name1, y = original_name2, fill = "yhat")) +
                geom_tile() +  # Use tiles to create the heatmap
                scale_fill_gradientn(colors = RColorBrewer::brewer.pal(9, "YlOrRd"), name = "Predicted\nProbability") +  # Color scale
                labs(title = paste("Interaction between", original_name1, "and", original_name2),
                     x = original_name1, y = original_name2) +
                theme_minimal() +
                theme(axis.title = element_text(size = 12), title = element_text(size = 14))

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

plot_interpretation_ice <- function(ice_data, original_feature_name, settings, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))
    
    plotData <- ggplot(ice_data, aes_string(x = original_feature_name, y = "yhat")) +
                geom_line(alpha = 0.3) +  # Use transparency to manage overplotting
                labs(title = paste("ICE Plot for", original_feature_name),
                     x = original_feature_name,
                     y = "Predicted Probability") +
                theme_minimal() +
                theme(legend.position = "none")  # Hide legend to reduce clutter

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

plot_interpretation_lime <- function(explanation, i, settings, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    # Update plot with appropriate title using original feature names
    plotData <- lime::plot_features(explanation)

    # Enhance title with descriptive names
    enhanced_title <- paste("LIME Explanation for Instance", i, "\nFeatures: ", paste(unique(explanation$feature), collapse=", "))
    plotData <- plotData + ggtitle(enhanced_title)

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}


plot_interpretation_iml <- function(model, data_testing, outcome, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))
    
    # Attempt to create a model object
    mod <- tryCatch({
        options(warn = 2)  # Treat all warnings as errors
        iml::Predictor$new(model, data = data_testing, y = outcome, type = "prob")
    }, error = function(e) {
        options(warn = 0)  # Reset warning behavior
        cat("===> WARNING: Failed to create model object: ", e$message, "\n")
        NULL  # Return NULL if there is an error
    })

    # Early exit if model object creation failed
    if (is.null(mod)) {
        return(NULL)
    }
    
    # Attempt to measure the interaction strength
    ia <- tryCatch({
        iml::Interaction$new(mod)
    }, error = function(e) {
        cat("===> WARNING: plot_interpretation_iml Failed to create interaction object: ", e$message, "\n")
        NULL  # Return NULL if there is an error
    })

    # Early exit if interaction object creation failed
    if (is.null(ia)) {
        return(NULL)
    }

    # Attempt to plot the interaction strength
    result <- tryCatch({
        plotData <- plot(ia) + ggtitle("Partial dependence")
        
        tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
        svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
        dev.off()
        
        tmp_path  # Return the path of the saved file
    }, error = function(e) {
        cat("===> WARNING: plot_interpretation_iml Failed during plotting: ", e$message, "\n")
        NULL  # Return NULL if there is an error
    })

    # Return the result which might be the path or NULL
    return(result)
}






