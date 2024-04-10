plot_auc_roc_training <- function(trainingPredictions, settings, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))
    
	unique_pred_levels <- unique(c(levels(trainingPredictions$pred), levels(trainingPredictions$obs)))

	plotData <- ggplot(trainingPredictions, aes(m=B, d=factor(obs, levels = unique_pred_levels), fill = method, color = method)) + 
	    geom_roc(hjust = -0.4, vjust = 1.5, linealpha = 1, increasing = TRUE, pointsize = settings$pointSize, labelsize = settings$labelSize) + 
	    coord_equal() +
	    style_roc(major.breaks = c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1),
	              minor.breaks = c(seq(0, 0.1, by = 0.01), seq(0.9, 1, by = 0.01)),
	              guide = TRUE, 
	              xlab = "False positive fraction (1-specificity)",
	              ylab = "1 - Specificity [False Positive Rate]", 
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

plot_auc_roc_testing_multiclass <- function(roc_data, auc_value, settings, tmp_hash){

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))
   
	plotData <- ggplot(roc_data, aes(x = FPR, y = TPR, color = Class, group = Class)) +
			    geom_line() +
			    coord_equal() +
			    style_roc(major.breaks = c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1),
			              minor.breaks = c(seq(0, 0.1, by = 0.01), seq(0.9, 1, by = 0.01)),
			              guide = TRUE, 
			              xlab = "False Positive Rate (1 - Specificity)",
			              ylab = "True Positive Rate (Sensitivity)",
			              theme = theme_bw) + 
			    geom_abline(slope = 1, intercept = 0, color = "#D3D3D3", alpha = 0.85, linetype="longdash") +
			    theme(text=element_text(size=settings$fontSize))  + 
			    scale_fill_brewer(palette=settings$colorPalette) +
			    labs(title = "Multi-class ROC Curves",
			         subtitle = paste("Comparison of model performance across different classes | AUC:", round(auc_value, 2)),
			         color = "Class Comparison") 


    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}


plot_auc_roc_trainig_multiclass <- function(roc_data, auc_labels, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	plotData <- ggplot(roc_data, aes(x = FPR, y = TPR, color = Class)) +
			    geom_line() + 
			    geom_abline(linetype = "dashed") +
			    scale_color_brewer(type = "qual", palette = "Set1", labels = auc_labels) +
			    labs(title = "Training ROC Curves", x = "False Positive Rate (FPR)", y = "True Positive Rate (TPR)") +
			    theme_minimal() +
			    theme(legend.title = element_blank()) +
			    guides(color = guide_legend(title = "Class (AUC)"))

    tmp_path <- tempfile(pattern = tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

plot_auc_roc_testing <- function(testingPredictions, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	plotData <- ggplot(testingPredictions, aes(m = predictionObject, d = factor(referenceData), fill = method, color = method)) + 
	    geom_roc(hjust = -0.4, vjust = 1.5, linealpha = 1, increasing = TRUE, pointsize = settings$pointSize, labelsize = settings$labelSize) + 
	    coord_equal() +
	    style_roc(major.breaks = c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1),
	              minor.breaks = c(seq(0, 0.1, by = 0.01), seq(0.9, 1, by = 0.01)),
	              guide = TRUE, 
	              xlab = "False positive fraction (1-specificity)",
	              ylab = "1 - Specificity [False Positive Rate]", 
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


plot_auc_roc_testing_full <- function(modelData, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	# unique_pred_levels <- unique(c(levels(modelPredictionData$pred), levels(modelPredictionData$obs)))

	referenceData <- modelData$info$data$testing[[modelData$info$outcome]]
	predictionObject <- modelData$predictions$raw$predictions

	plotData <- mplot_full(tag=referenceData, score=predictionObject[, "B"])


    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}
# https://bgreenwell.github.io/pdp/articles/pdp.html
plot_partial_dependence <- function(modelData, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	# unique_pred_levels <- unique(c(levels(modelPredictionData$pred), levels(modelPredictionData$obs)))


	p_load(plotmo)
	plotData <- plotmo(modelData$training$raw$data, pmethod="partdep", all1=FALSE, all2=FALSE)

    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}

# https://christophm.github.io/interpretable-ml-book/interaction.html
plot_feature_interaction <- function(modelData, settings, tmp_hash){
    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

	# unique_pred_levels <- unique(c(levels(modelPredictionData$pred), levels(modelPredictionData$obs)))

	p_load("iml")

	# Create a model object
	mod <- iml::Predictor$new(modelData$training$raw$data, data = modelData$info$data$testing, y = modelData$info$outcome, type = "prob")
	# Measure the interaction strength
	ia <- iml::Interaction$new(mod)

	plotData <- plot(ia) + ggtitle("Partial dependence")

    tmp_path <- tempfile(pattern =  tmp_hash, tmpdir = tempdir(), fileext = ".svg")
    svg(tmp_path, width = settings$plot_size * settings$aspect_ratio, height = settings$plot_size, pointsize = 12, onefile = TRUE, family = "Arial", bg = "white", antialias = "default")
        print(plotData)
    dev.off()  

    return(tmp_path) 
}
