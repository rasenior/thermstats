#' SHDI
#'
#' Helper function to calculate Shannon Diversity Index.
#' @param x Numeric vector or matrix.
#' @param na.rm Logical. Should missing values be removed? Defaults to TRUE.
#' @keywords internal

SHDI <- function(x, na.rm = TRUE) {
  # Convert to numeric vector if matrix
  if (is.matrix(x)) x <- as.numeric(x)
  if (na.rm) x <- stats::na.omit(x)
  
  # Count all occurrences of each unique temperature
  props <- table(x) / length(x)
  
  # Calculate Shannon diversity index
  result <- -sum(props * log(props))

  return(result)
}
