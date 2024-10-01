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
        theme(text=element_text(size=settings$fontSize))  + 
        scale_fill_brewer(palette=settings$colorPalette)

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
                theme(text=element_text(size=settings$fontSize))

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

plot_interpretation_ice <- function(ice_data, original_feature_name, settings, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))
    
    original_feature_name <- paste0("`", original_feature_name, "`")
    
    plotData <- ggplot(ice_data, aes_string(x = original_feature_name, y = "yhat")) +
                geom_line(alpha = 0.3) +  # Use transparency to manage overplotting
                labs(title = paste("ICE Plot for", original_feature_name),
                     x = original_feature_name,
                     y = "Predicted Probability") +
                theme(legend.position = "none", text=element_text(size=settings$fontSize))  + 
                scale_fill_brewer(palette=settings$colorPalette)

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
    plotData <- plotData + ggtitle(enhanced_title) +
                theme(text=element_text(size=settings$fontSize))  + 
                scale_fill_brewer(palette=settings$colorPalette)

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}


plot_interpretation_iml_featureimp <- function(mod, rename_vector_features, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    out <- iml::FeatureImp$new(mod, loss = "ce", features = NULL)

    plotData <- plot(out)
    plotData <- plotData + scale_y_discrete(labels = rename_vector_features) +
                theme(text=element_text(size=settings$fontSize))  + 
                scale_fill_brewer(palette=settings$colorPalette)

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

plot_interpretation_iml_interaction <- function(mod, rename_vector_features, rename_vector_outcome, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    out <- iml::Interaction$new(mod, feature = NULL)
    
    plotData <- plot(out)
    plotData <- plotData + facet_wrap(~.class, labeller = as_labeller(rename_vector_outcome))
    plotData <- plotData + scale_y_discrete(labels = rename_vector_features) +
                theme(text=element_text(size=settings$fontSize))  + 
                scale_fill_brewer(palette=settings$colorPalette)

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

plot_interpretation_iml_featureeffect_ale <- function(mod, features_to_compare, rename_vector_features, rename_vector_outcome, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    out <- tryCatch({
        suppressWarnings({
            # Your function call that might generate warnings
            iml::FeatureEffect$new(mod, feature = features_to_compare, method = "ale")
        })
    }, error = function(e) {
        # Handle errors by returning NULL or logging
        print(paste0("===> ERROR: ", e$message))  # e$message to print only the message part of the error
        NULL  # Return NULL on error
    })

    if(is.null(out)){
        return(NULL)
    }

    p <- plot(out)
    p <- p + facet_wrap(~.class, labeller = as_labeller(rename_vector_outcome))
    if (length(features_to_compare) == 1) {
        p <- p + xlab(rename_vector_features[features_to_compare])
    } else {
        ## rename both features
        p <- p + scale_x_discrete(labels = rename_vector_features[features_to_compare[1]]) + xlab(rename_vector_features[features_to_compare[1]])
        p <- p + scale_y_discrete(labels = rename_vector_features[features_to_compare[2]]) + ylab(rename_vector_features[features_to_compare[2]])
    }
    plotData <- p +
                theme(text=element_text(size=settings$fontSize))

    print(tmp_hash)

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")

    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

plot_interpretation_iml_featureeffect_pdp_ice <- function(mod, process_feature, rename_vector_outcome, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    out <- iml::FeatureEffect$new(mod, feature = process_feature$remapped, method = "pdp+ice")
    p <- plot(out)
    p <- p + facet_wrap(~.class, labeller = as_labeller(rename_vector_outcome))
    p <- p + xlab(process_feature$original)
    plotData <- p +
                theme(text=element_text(size=settings$fontSize))  + 
                scale_fill_brewer(palette=settings$colorPalette)

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}







