## TRAINIG ROC (PLOT 1):
## One-vs-All Strategy | SINGLE
roc_training_single <- function(modelData, settings, resampleID, outcome_mappings){

    # Map internal class names to external class names
    class_mapping <- setNames(modelData$info$outcome_mapping$class_original, modelData$info$outcome_mapping$class_remapped)

    # Extract observed class labels from the model data
    observed <- modelData$training$raw$data$pred$obs

    # Get the internal class names in desired order
    classes <- sort(unique(observed), decreasing = TRUE)

    # Classes defined in outcome_mappings
    defined_classes <- unique(outcome_mappings$class_remapped)

    roc_list <- list()

    # Compute ROC object for each class
    for (class in classes) {
        if (class %in% defined_classes) {
            cat(paste0("===> INFO: Calculating ROC TRAINING for class: ", class, "\n"))
            binary_observed <- ifelse(observed == class, 1, 0)

            if (length(unique(binary_observed)) == 1) {
                cat(paste("Skipping ROC for class due to insufficient data:", class, "\n"))
                next  # Skip this iteration if binary conversion failed to produce two classes
            }

            if (is.null(modelData$training$raw$data$pred[[class]])) {
                cat(paste("Skipping ROC for class due to missing column in pred data:", class, "\n"))
                next
            }

            # Compute ROC curve using pROC
            roc_obj <- pROC::roc(binary_observed, modelData$training$raw$data$pred[[class]])
            # Store ROC object for later use
            roc_list[[class]] <- roc_obj
        }
    }

    # Initialize an empty data frame for ROC data
    roc_data <- data.frame(FPR = numeric(), TPR = numeric(), Thresholds = numeric(), Class = factor())

    # Extract and bind data for each class
    for (class in names(roc_list)) {
        roc_item <- roc_list[[class]]
        # Create a temporary data frame with ROC data for the current class
        tmp_data <- data.frame(
            FPR = 1 - roc_item$specificities,
            TPR = roc_item$sensitivities,
            Thresholds = roc_item$thresholds,
            Class = class  # Use the internal class name directly
        )
        # Bind this temporary data frame to the main ROC data frame
        roc_data <- rbind(roc_data, tmp_data)
    }

    if (nrow(roc_data) < 1) {
        return(list(roc_data = NULL, auc_labels = NULL))
    }

    # Map internal class names to external readable names and set factor levels
    class_levels <- class_mapping[classes]
    # Remove NA values in case some classes don't have mappings
    class_levels <- class_levels[!is.na(class_levels)]
    classes <- classes[classes %in% names(class_levels)]

    # Set the Class factor with levels in desired order
    roc_data$Class <- factor(roc_data$Class, levels = classes, labels = class_levels)

    # Order roc_data by Class
    roc_data <- roc_data[order(roc_data$Class), ]

    # Calculate AUC values and map names to external class names
    auc_values <- sapply(roc_list, function(roc_obj) as.numeric(pROC::auc(roc_obj)))
    auc_class_names <- class_mapping[names(auc_values)]
    names(auc_values) <- auc_class_names

    # Ensure auc_values are ordered according to class_levels
    auc_values_ordered <- auc_values[class_levels]

    # Remove any NA values in auc_values_ordered
    valid_indices <- !is.na(auc_values_ordered)
    auc_values_ordered <- auc_values_ordered[valid_indices]
    class_levels_ordered <- class_levels[valid_indices]

    # Generate AUC labels in the format "Class - (AUC)"
    auc_labels <- sprintf("%s - (%.2f)", class_levels_ordered, auc_values_ordered)

    # Optionally, name the labels by their class for easier referencing in plots
    names(auc_labels) <- class_levels_ordered

    return(list(roc_data = roc_data, auc_labels = auc_labels))
}

roc_training_multi <- function(modelData, settings, resampleID, outcome_mappings){

    class_mapping <- setNames(modelData$info$outcome_mapping$class_original, modelData$info$outcome_mapping$class_remapped)
    observed <- modelData$training$raw$data$pred$obs
    classes <- sort(unique(observed), decreasing = TRUE)

    # Classes defined in outcome_mappings
    defined_classes <- unique(outcome_mappings$class_remapped)

    # Initialize an empty data frame for ROC data
    roc_data <- data.frame(FPR = numeric(), TPR = numeric(), Class = factor(), Comparison = factor(), Thresholds = numeric())
    auc_values <- list()  # Use a list to store AUC values for easier handling

    # Loop through each class and compute ROC against each other class
    for (primary_class in classes) {

        if (primary_class %in% defined_classes) {
            for (comparison_class in classes) {
                if (primary_class != comparison_class) {
                    binary_observed <- ifelse(observed == primary_class, 1, 0)

                    if (length(unique(binary_observed)) == 1) {
                        print(paste("Skipping ROC for class due to insufficient data:", primary_class))
                        next  # Skip this iteration if binary conversion failed to produce two classes
                    }

                    if (is.null(modelData$training$raw$data$pred[[comparison_class]])) {
                        print(paste("Skipping ROC for class due to missing column in pred data:", comparison_class))
                        next
                    }

                    binary_predicted <- modelData$training$raw$data$pred[[comparison_class]]
                    
                    # Compute ROC curve using pROC
                    roc_obj <- pROC::roc(binary_observed, binary_predicted)
                    
                    # Create a temporary data frame with ROC data
                    tmp_data <- data.frame(
                        FPR = 1 - roc_obj$specificities,
                        TPR = roc_obj$sensitivities,
                        Thresholds = roc_obj$thresholds,
                        Class = class_mapping[primary_class],
                        Comparison = class_mapping[comparison_class]  # New field for comparison class
                    )
                    
                    # Bind this temporary data frame to the main ROC data frame
                    roc_data <- rbind(roc_data, tmp_data)
                    
                    # Store AUC value in the list with an appropriate label
                    auc_values[[paste(class_mapping[primary_class], "vs", class_mapping[comparison_class])]] <- pROC::auc(roc_obj)
                }
            }
        }
    }

    if(nrow(roc_data) < 1){
        return(list(roc_data = NULL))
    }

    # Assuming 'Class' and 'Comparison' are already in the desired format but need pairing
    roc_data$Comparison <- with(roc_data, paste(Class, "vs", Comparison))

    # Now adjust the creation of AUC labels to match this new pairing format
    auc_labels <- sapply(names(auc_values), function(name) {
        sprintf("%s - (%.2f)", name, auc_values[[name]])
    })

    # Create a dataframe for AUC labels
    auc_labels <- data.frame(
        Label = auc_labels,
        ClassComparison = names(auc_values)
    )

    roc_data$Comparison <- as.character(roc_data$Comparison)
    auc_labels$ClassComparison <- as.character(auc_labels$ClassComparison)

    # Merge AUC labels into the roc_data
    roc_data <- base::merge(roc_data, auc_labels, by.x = "Comparison", by.y = "ClassComparison", all.x = TRUE)

    return(list(roc_data = roc_data))
}
