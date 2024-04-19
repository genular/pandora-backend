update_class_labels_with_auc <- function(combined_label, mapping, auc_values) {
    
    if (!is.character(combined_label)) {
        if (is.null(combined_label)) {
            combined_label <- ""
        } else {
            combined_label <- as.character(combined_label)
        }
    }

    class_parts <- strsplit(combined_label, "/")[[1]]
    original_classes <- sapply(class_parts, function(part) {
        if (part %in% names(mapping)) {
            return(mapping[part])
        } else {
            return(part)  # Return the part as is if not found in the mapping
        }
    })
    label_with_auc <- paste(original_classes, collapse = " vs ")
    final_label <- sprintf("%s - (%.2f)", label_with_auc, auc_values[[combined_label]])
    return(final_label)
}
