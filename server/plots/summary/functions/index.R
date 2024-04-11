# Function to update combined class labels
update_class_labels <- function(combined_label, mapping) {
  # Split the combined label by "/"
  class_parts <- strsplit(combined_label, "/")[[1]]
  
  # Map each part to its original class name using the provided mapping
  original_classes <- sapply(class_parts, function(part) mapping[part])
  
  # Combine the original class names back with "/"
  combined_original <- paste(original_classes, collapse = "/")
  
  return(combined_original)
}
