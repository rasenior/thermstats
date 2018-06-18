#' get_stats
#'
#' Calculate summary and spatial statistics across a single matrix or raster.
#' @param val_mat A numeric matrix or raster.
#' @param matrix_id The matrix ID (optional). Useful when iterating over numerous matrices.
#' @param get_patches Whether to identify hot and cold spots. Defaults to TRUE.
#' @param k Number of neighbours to use when calculating nearest neighbours
#' using \code{spdep::}\code{\link[spdep]{knearneigh}}.
#' @param style Style to use when calculating neighbourhood weights using
#'  \code{spdep::}\code{\link[spdep]{nb2listw}}.
#' @param mat_proj Spatial projection. Optional, but necessary for geographic
#' data to plot correctly.
#' @param mat_extent Spatial extent. Optional, but necessary for geographic
#' data to plot correctly.
#' @param return_vals Which values to return? Any combination of the dataframe
#' (\code{df}), SpatialPolygonsDataFrame of hot and cold patches
#' (\code{patches}) and patch statistics dataframe (\code{pstats}). Note that
#' \code{pstats} will always be returned -- if this is not desired, use
#' \code{\link{get_patches}} instead.
#' @param pixel_fns The names of the summary statistics to apply.
#' @param ... Use to specify summary statistics that should be calculated across
#' all pixels. Several helper functions are included for use here:
#' \code{\link{perc_5}}, \code{\link{perc_95}},
#' \code{\link{SHDI}}, \code{\link{SIDI}},
#' \code{\link{kurtosis}} and \code{\link{skewness}}.
#' @return A list containing:
#'  \item{df}{A dataframe with one row for each pixel, and variables denoting:
#'  the pixel value (val); the original spatial location of the pixel (x and y);
#'  its patch classification (G_bin) into a hot (1), cold (-1) or no patch (0)
#'  according to the Z value (see \code{spdep::}\code{\link[spdep]{localG}});
#'  the unique ID of the patch in which the pixel fell;
#'  and the matrix ID (if applicable).}
#'  \item{patches}{A SpatialPolygonsDataFrame of hot and cold patches. Hot
#'  patches have a value of 1, and cold patches a value of -1.}
#'  \item{pstats}{A dataframe with patch statistics for hot patches and cold
#'  patches, respectively. See \code{\link{patch_stats}} for details of all the
#'  statistics returned.}
#' @examples
#'
#' # FLIR temperature matrix ---------------------------------------------------
#' # Load raw data
#' raw_dat <- flir_raw$raw_dat
#' camera_params <- flir_raw$camera_params
#' metadata <- flir_raw$metadata
#'
#' # Define individual matrix and raster
#' val_mat <- raw_dat$`8565`
#' val_raster <- raster::raster(val_mat)
#'
#' # Define matrix ID (the photo number in this case)
#' matrix_id <- "8565"
#'
#' # Get stats!
#' get_stats(val_mat = val_mat,
#'           matrix_id = matrix_id,
#'           k = 8,
#'           style = "W",
#'           mat_proj = NULL,
#'           mat_extent = NULL,
#'           return_vals = "pstats",
#'           mean, min, max)
#' get_stats(val_mat = val_raster,
#'           matrix_id = matrix_id,
#'           k = k,
#'           style = style,
#'           mat_proj = NULL,
#'           mat_extent = NULL,
#'           return_vals = "pstats",
#'           mean, min, max)
#'
#' # Worldclim2 temperature raster ---------------------------------------------
#'
#' # Dataset 'worldclim_sulawesi' represents mean January temperature for the
#' # island of Sulawesi
#'
#' # Define projection and extent
#' mat_proj <- projection(worldclim_sulawesi)
#' mat_extent <- extent(worldclim_sulawesi)
#'
#' # Find hot and cold patches
#' worldclim_results <-
#'  get_stats(val_mat = worldclim_sulawesi,
#'            matrix_id = "sulawesi",
#'            k = 8,
#'            style = "W",
#'            mat_proj = mat_proj,
#'            mat_extent = mat_extent,
#'            return_vals = c("df", "patches", "pstats"),
#'            mean, min, max)
#'
#' # Plot!
#' df <- worldclim_results$df
#' patches <- worldclim_results$patches
#' plot_patches(df, patches, print_plot = TRUE, save_plot = FALSE)
#' @export

get_stats <- function(val_mat,
                      matrix_id = NULL,
                      get_patches = TRUE,
                      k = 8,
                      style = "W",
                      mat_proj = NULL,
                      mat_extent = NULL,
                      return_vals = c("df","patches","pstats"),
                      pixel_fns = NULL,
                      ...){

  # If raster, coerce to matrix ------------------------------------------------
  if(class(val_mat)[1] == "RasterLayer"){
    val_mat <- raster::as.matrix(val_mat)
  }

  # Pixel statistics -----------------------------------------------------------
  # -> these statistics are calculated across all pixels

  if(is.null(pixel_fns)){
    # Define function names for pixel stats
    pixel_fns <-
      paste(match.call(expand.dots = FALSE)$...)
  }
  # Get pixel stats
  pixel_stats <- multi_sapply(val_mat,...)

  colnames(pixel_stats) <- pixel_fns

  # Patch statistics -----------------------------------------------------------
  # -> these statistics are calculated for hot and cold patches

  # return_vals must include pstats (otherwise just use get_patches)
  if(!("pstats" %in% return_vals)) return_vals <- c(return_vals, "pstats")

  if(get_patches){
    all_stats <- get_patches(val_mat = val_mat,
                             matrix_id = matrix_id,
                             k = k,
                             style = style,
                             mat_proj = mat_proj,
                             mat_extent = mat_extent,
                             return_vals = return_vals)
    # Return results -------------------------------------------------------------

    # If length one then only includes pstats
    if(length(return_vals) == 1){
      all_stats <- cbind(pixel_stats, all_stats)
    }else{
      all_stats[["pstats"]] <- cbind(pixel_stats, all_stats[["pstats"]])
    }

    return(all_stats)
  }else{
    return(pixel_stats)
  }

}