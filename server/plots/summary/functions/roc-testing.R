roc_testing_single <- function(modelData, settings, resampleID, outcome_mappings){

    # Create a mapping from internal class names to original class names
    class_mapping <- setNames(modelData$info$outcome_mapping$class_original, modelData$info$outcome_mapping$class_remapped)

    # Get the observed classes
    observed <- modelData$training$raw$data$pred$obs

    # Get the internal class names in desired order
    classes <- sort(unique(observed), decreasing = TRUE)

    # Get the external class names in desired order
    class_levels <- class_mapping[classes]

    # Ensure that class_levels does not contain NA values
    class_levels <- class_levels[!is.na(class_levels)]

    # Classes defined in outcome_mappings
    defined_classes <- unique(outcome_mappings$class_remapped)

    # Initialize an empty dataframe to store ROC data
    roc_data <- data.frame(FPR = numeric(), TPR = numeric(), Thresholds = numeric(), Class = factor(), AUC = numeric())

    # Loop over each class in the AUROC list, assuming each class has its separate ROC data
    for(class_name in names(modelData$predictions$AUROC)) {
        if(class_name == "Multiclass") {
            next
        }

        if (class_name %in% defined_classes) {
            # Access the ROC object and AUC value for each class
            roc_obj <- modelData$predictions$AUROC[[class_name]]$ROC
            auc_value <- as.numeric(modelData$predictions$AUROC[[class_name]]$AUC)
            
            # Check if the roc_obj is correctly structured and contains the data
            if(is.list(roc_obj) && "specificities" %in% names(roc_obj) && "sensitivities" %in% names(roc_obj)) {
                tmp_data <- data.frame(
                    FPR = 1 - roc_obj$specificities,
                    TPR = roc_obj$sensitivities,
                    Thresholds = roc_obj$thresholds,
                    Class = class_name,  # Use the class name directly
                    AUC = rep(auc_value, length(roc_obj$specificities))  # Repeat AUC value for length of the specifics
                )
                # Bind this temporary data frame to the main ROC data frame
                roc_data <- rbind(roc_data, tmp_data)
            }
        }
    }

    if(nrow(roc_data) < 1){
        return(list(roc_data = NULL, auc_labels = NULL))
    }

    # Map internal class names to external readable names and set factor levels
    roc_data$Class <- factor(roc_data$Class, levels = classes, labels = class_mapping[classes])

    # Order roc_data by Class
    roc_data <- roc_data[order(roc_data$Class), ]

    # Calculate the average AUC for each class
    average_auc_per_class <- aggregate(AUC ~ Class, data = roc_data, FUN = mean)

    # Ensure Class is a factor with levels in desired order
    average_auc_per_class$Class <- factor(average_auc_per_class$Class, levels = levels(roc_data$Class))

    # Order average_auc_per_class by Class
    average_auc_per_class <- average_auc_per_class[order(average_auc_per_class$Class), ]

    # Create labels in the format "Class - (AUC)"
    auc_labels <- sprintf("%s - (%.2f)", average_auc_per_class$Class, average_auc_per_class$AUC)

    # Optionally, name the labels by their class for easier referencing in plots
    names(auc_labels) <- as.character(average_auc_per_class$Class)

    return(list(roc_data = roc_data, auc_labels = auc_labels))
}


roc_testing_multi <- function(modelData, settings, resampleID, outcome_mappings){
    # Retrieve class mapping from model data
    class_mapping <- setNames(modelData$info$outcome_mapping$class_original, modelData$info$outcome_mapping$class_remapped)

    # Get ROC objects and AUC values
    roc_objs <- modelData$predictions$AUROC$Multiclass$ROC$rocs
    auc_values <- list()  # Initialize a list to store AUC values

    # Classes defined in outcome_mappings
    defined_classes <- unique(outcome_mappings$class_remapped)

    # Initialize an empty data frame to store combined ROC data
    roc_data_df <- data.frame(FPR = numeric(), TPR = numeric(), Thresholds = numeric(), Class = character())

    # Iterate through each comparison class pair in roc_objs
    for (class_comp in names(roc_objs)) {

        classes <- strsplit(class_comp, "/")[[1]]
        if (!all(classes %in% defined_classes)) next  # Skip comparisons involving undefined classes

        roc_item <- roc_objs[[class_comp]][[1]]
        
        # Check if roc_item is correctly structured and contains the data
        if (is.list(roc_item) && "specificities" %in% names(roc_item) && "sensitivities" %in% names(roc_item)) {
            # Compute AUC for the current ROC object
            auc_values[[class_comp]] <- pROC::auc(roc_item$sensitivities, roc_item$specificities)
            
            # Prepare ROC data frame for current comparison
            tmp_data <- data.frame(
                FPR = 1 - roc_item$specificities,
                TPR = roc_item$sensitivities,
                Thresholds = roc_item$thresholds,
                Class = class_comp  # Use the class comparison label directly
            )
            
            # Append data to the main ROC data frame
            roc_data_df <- rbind(roc_data_df, tmp_data)
        }
    }
    if(nrow(roc_data_df) < 1){
        return(list(roc_data = NULL))
    }

    # Update the Class column in roc_data_df to include AUC values
    roc_data_df$Label <- sapply(roc_data_df$Class, update_class_labels_with_auc, mapping = class_mapping, auc_values = auc_values)

    return(list(roc_data = roc_data_df))
}
