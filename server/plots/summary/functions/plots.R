plot_auc_roc_multiclass_testing <- function(roc_data, settings, tmp_hash, method){ 

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))
   
	plotData <- ggplot(roc_data, aes(x = FPR, y = TPR, color = Label, group = Class)) +
			    geom_line() +
			    coord_equal() +
			    style_roc(major.breaks = c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1),
			              minor.breaks = c(seq(0, 0.1, by = 0.01), seq(0.9, 1, by = 0.01)),
			              guide = TRUE, 
			              xlab = "False Positive Rate (FPR) (1 - Specificity)",
			              ylab = "True Positive Rate (TPR) (Sensitivity)",
			              theme = theme_bw) + 
			    geom_abline(slope = 1, intercept = 0, color = "#D3D3D3", alpha = 0.85, linetype="longdash") +
			    theme(text=element_text(size=settings$fontSize))  + 
			    scale_fill_brewer(palette=settings$colorPalette) +
			    labs(title = paste0("Multi-class ROC Curves for ", method),
			         subtitle = paste("Comparison of model performance across different classes (testing-m)"),
			         color = "Class Comparison (AUC)") 


    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}


plot_auc_roc_multiclass_testing_single <- function(roc_data, auc_labels, settings, tmp_hash, method){ 

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))
   
	plotData <- ggplot(roc_data, aes(x = FPR, y = TPR, color = Class)) +
			    geom_line() + 
			    coord_equal() +
			    style_roc(major.breaks = c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1),
			              minor.breaks = c(seq(0, 0.1, by = 0.01), seq(0.9, 1, by = 0.01)),
			              guide = TRUE, 
			              xlab = "False Positive Rate (FPR) (1 - Specificity)",
			              ylab = "True Positive Rate (TPR) (Sensitivity)",
			              theme = theme_bw) + 
			    geom_abline(slope = 1, intercept = 0, color = "#D3D3D3", alpha = 0.85, linetype="longdash") +
			    scale_color_brewer(type = "qual", palette = "Set1", labels = auc_labels) +
			    theme(text=element_text(size=settings$fontSize))  + 
			    scale_fill_brewer(palette=settings$colorPalette) +
			    labs(title = paste0("Multi-class ROC Curves (One-vs-All) for ", method),
			         subtitle = paste("Comparison of model performance across different classes (testing-s)"),
			         color = "Class Comparison") 


    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

plot_auc_roc_multiclass_training <- function(roc_data, settings, tmp_hash, method){ 

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))
   
	plotData <- ggplot(roc_data, aes(x = FPR, y = TPR, color = Label, group = Class)) +
			    geom_line() +
			    coord_equal() +
			    style_roc(major.breaks = c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1),
			              minor.breaks = c(seq(0, 0.1, by = 0.01), seq(0.9, 1, by = 0.01)),
			              guide = TRUE, 
			              xlab = "False Positive Rate (FPR) (1 - Specificity)",
			              ylab = "True Positive Rate (TPR) (Sensitivity)",
			              theme = theme_bw) + 
			    geom_abline(slope = 1, intercept = 0, color = "#D3D3D3", alpha = 0.85, linetype="longdash") +
			    theme(text=element_text(size=settings$fontSize))  + 
			    scale_fill_brewer(palette=settings$colorPalette) +
			    labs(title = paste0("Multi-class ROC Curves for ", method),
			         subtitle = paste("Comparison of model performance across different classes (training-m)"),
			         color = "Class Comparison (AUC)") 


    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

plot_auc_roc_multiclass_training_single <- function(roc_data, auc_labels, settings, tmp_hash, method){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	plotData <- ggplot(roc_data, aes(x = FPR, y = TPR, color = Class)) +
			    geom_line() + 
			    coord_equal() +
			    style_roc(major.breaks = c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1),
			              minor.breaks = c(seq(0, 0.1, by = 0.01), seq(0.9, 1, by = 0.01)),
			              guide = TRUE, 
			              xlab = "False Positive Rate (FPR) (1 - Specificity)",
			              ylab = "True Positive Rate (TPR) (Sensitivity)",
			              theme = theme_bw) + 
			    geom_abline(slope = 1, intercept = 0, color = "#D3D3D3", alpha = 0.85, linetype="longdash") +
			    scale_color_brewer(type = "qual", palette = "Set1", labels = auc_labels) +
			    theme(text=element_text(size=settings$fontSize))  + 
			    scale_fill_brewer(palette=settings$colorPalette) +
			    labs(title = paste0("Multi-class ROC Curves (One-vs-All) for ", method),
			         subtitle = paste("Comparison of model performance across different classes (training-s)"),
			         color = "Class Comparison") 

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}



### TWO CLASS PLOTS
plot_auc_roc_training_probabilities <- function(trainingPredictions, outcome_mapping_primary, outcome_mapping_secondary, settings, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    if(!is.numeric(trainingPredictions[[outcome_mapping_primary$class_remapped]])) {
        trainingPredictions[[outcome_mapping_primary$class_remapped]] <- as.numeric(trainingPredictions[[outcome_mapping_primary$class_remapped]])
    }
    
	unique_pred_levels <- unique(c(levels(trainingPredictions$pred), levels(trainingPredictions$obs)))

	plotData <- ggplot(trainingPredictions, aes_string(m=outcome_mapping_primary$class_remapped, d="factor(obs, levels = unique_pred_levels)", fill="method", color="method")) + 
	    geom_roc(hjust = -0.4, vjust = 1.5, linealpha = 1, increasing = TRUE, pointsize = settings$pointSize, labelsize = settings$labelSize) + 
	    coord_equal() +
	    style_roc(major.breaks = c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1),
	              minor.breaks = c(seq(0, 0.1, by = 0.01), seq(0.9, 1, by = 0.01)),
	              guide = TRUE, 
	              xlab = paste0("False Positive Rate (FPR) (1 - Specificity)"),
	              ylab = paste0("True Positive Rate (TPR) (Sensitivity)"),
	              theme = theme_bw) + 
	    geom_abline(slope = 1, intercept = 0, color = "#D3D3D3", alpha = 0.85, linetype="longdash") +
	    theme(text=element_text(size=settings$fontSize))  + 
	    scale_fill_brewer(palette=settings$colorPalette)


    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

plot_auc_roc_testing_probabilities <- function(testingPredictions, outcome_mapping_primary, outcome_mapping_secondary, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	plotData <- ggplot(testingPredictions, aes(m = predictionObject, d = factor(referenceData), fill = method, color = method)) + 
	    geom_roc(hjust = -0.4, vjust = 1.5, linealpha = 1, increasing = TRUE, pointsize = settings$pointSize, labelsize = settings$labelSize) + 
	    coord_equal() +
	    style_roc(major.breaks = c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1),
	              minor.breaks = c(seq(0, 0.1, by = 0.01), seq(0.9, 1, by = 0.01)),
	              guide = TRUE, 
	              xlab = "False Positive Rate (FPR) (1 - Specificity)",
	              ylab = "True Positive Rate (TPR) (Sensitivity)",
	              theme = theme_bw) + 
	    geom_abline(slope = 1, intercept = 0, color = "#D3D3D3", alpha = 0.85, linetype="longdash") +
	    theme(text=element_text(size=settings$fontSize))  + 
	    scale_fill_brewer(palette=settings$colorPalette)


    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}


plot_auc_roc_class_labels <- function(predictions, outcome_mapping_primary, outcome_mapping_secondary, settings, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	# Check if 'pred' column exists and has non-NA data
	if("pred" %in% names(predictions) && any(!is.na(predictions$pred))) {
	    predictions$numeric_pred <- as.numeric(predictions$pred == outcome_mapping_primary$class_remapped)
	} else if("predictionObject" %in% names(predictions) && any(!is.na(predictions$predictionObject))) {
	    # Rename referenceData to obs and predictionObject to pred
	    names(predictions)[names(predictions) == "referenceData"] <- "obs"
	    names(predictions)[names(predictions) == "predictionObject"] <- "pred"
	    # Recalculate numeric_pred based on the renamed columns
	    predictions$numeric_pred <- as.numeric(predictions$pred == outcome_mapping_primary$class_remapped)
	} else {
	    # Handle cases where neither column is appropriate
	    print("===> ERROR: No valid prediction data found.")
	}
    
    # Initialize a list to store ROC objects for each model
    roc_list <- list()

    # Calculate ROC for each method
    methods <- unique(predictions$method)
    for (method in methods) {
        roc_data <- roc(predictions$obs[predictions$method == method], 
                        predictions$numeric_pred[predictions$method == method], 
                        levels = rev(levels(predictions$obs)))
        roc_list[[method]] <- roc_data
    }
    
    # Create a dataframe for plotting
    roc_plot_data <- do.call(rbind, lapply(names(roc_list), function(m) {
        data.frame(
            FPR = 1 - roc_list[[m]]$specificities,
            TPR = roc_list[[m]]$sensitivities,
            Method = m
        )
    }))
    
	plotData <- ggplot(roc_plot_data, aes(x = FPR, y = TPR, color = Method)) +
		        geom_line() +
		        geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray") +
			    labs(title = paste0("ROC Curves by Model. Positive class: ", outcome_mapping_primary$class_original),
			         subtitle = "Comparison of model performance across different methods",
			         x = "False Positive Rate (1 - Specificity)",
			         y = "True Positive Rate (Sensitivity)",
			         color = "Method") +
		        theme_minimal() +
		        theme(text = element_text(size = settings$fontSize)) +
		        scale_color_brewer(palette = settings$colorPalette)

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}
