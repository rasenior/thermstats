#' skewness
#'
#' Helper function to calculate skewness, using
#' \code{moments::}\code{\link[moments]{skewness}}.
#' @param x Numeric vector or matrix.
#' @param na.rm Logical. Should missing values be removed? Defaults to TRUE.
#' @keywords internal

skewness <- function(x, na.rm = TRUE) {
  # Convert to numeric vector if matrix
  if (is.matrix(x)) x <- as.numeric(x)
  if (na.rm) x <- stats::na.omit(x)
  
  if (requireNamespace("moments", quietly = TRUE)) {
      return(moments::skewness(x))
  }else {
      stop("Requires package 'moments'")
  }
}
