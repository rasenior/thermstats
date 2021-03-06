#' batch_extract
#'
#' Batch extraction of raw data from FLIR thermal images.
#' @param in_dir Path to directory where thermal images are stored.
#' @param write_results Should the results be written as an Rdata file?
#' Defaults to true.
#' @param out_dir Path to directory where output Rdata file will be stored.
#' Defaults to working directory.
#' @param file_name File name (without extension). Defaults to NULL, with the 
#' name 'flir_raw_' plus the current date. File format is .Rds 
#' @param inc Vector of file names to include. Defaults to NULL, meaning 
#' all files are included.
#' @param exc Vector of file names to exclude. Defaults to NULL, meaning 
#' all files are included.
#' @param exiftoolpath Passed directly to 
#' \code{Thermimage::}\code{\link[Thermimage]{readflirJPG}}: 
#' "A character string that determines whether ExifTool has been 'installed' 
#' (\url{http://www.sno.phy.queensu.ca/~phil/exiftool/}) or not. If ExifTool has been 
#' installed in a specific location, use to direct to the folder location."
#' @return A list containing:
#'  \item{raw_dat}{A list with one element per input thermal image. Each element
#'  is a numeric matrix of the raw infrared data.}
#'  \item{camera_params}{A dataframe of callibration constants unique to each
#'  camera.}
#' @details Batch implementation of \code{Thermimage::}\code{\link[Thermimage]{readflirJPG}}.
#' 
#' Note that ExifTool is essential for this function to work correctly. See the
#' documentation of \code{Thermimage::}\code{\link[Thermimage]{readflirJPG}}:
#' 
#' "Exiftool should install on most operating systems. Consult with 
#' \url{http://www.sno.phy.queensu.ca/~phil/exiftool/} for information on installing 
#' Exiftool. If trouble installing, download Exiftool and set exiftoolpath to 
#' the custom folder location. To test if the custom path to Exiftool will work 
#' on your OS, try your own system or system2 call: 
#' system2('/custompath/exiftool') to see if you get an error or not."
#' @references
#' ExifTool Command line tool: \url{http://www.sno.phy.queensu.ca/~phil/exiftool/}
#' @examples
#' # Batch extract four FLIR thermal images included in this package.
#' results <-
#'     batch_extract(system.file("extdata", package = "ThermStats"),
#'                   write_results = FALSE)
#' @export
#'
batch_extract <- function(in_dir,
                          write_results = TRUE,
                          out_dir = NULL,
                          file_name = NULL,
                          inc = NULL,
                          exc = NULL,
                          exiftoolpath = "installed"){

  # File names --------------------------------------------------------------

  # Get file names
  file.names <- list.files(in_dir, full.names = TRUE)
  
  # Subset files
  if(!(is.null(inc))) {
    file.names <- file.names[file.names %in% file.path(in_dir, inc)]
  }
  if(!(is.null(exc))) {
    file.names <- file.names[!(file.names %in% file.path(in_dir, exc))]
  }
  
  # Remove path & file extension to get photo number
  photo_no <- basename(file.names)
  photo_no <- gsub("FLIR","",photo_no)
  photo_no <- gsub(".jpg","", photo_no)

  # Create empty list to populate with temperature matrices
  raw_dat <- vector("list", length(photo_no))
  names(raw_dat) <- photo_no

  # Extract FLIR data -------------------------------------------------------

  for (i in 1:length(file.names)) {
    cat("Processing file", i, "of", length(file.names),"\n")
    cat("Reading file...","\n")

    # Try and read in each FLIR file
    photo_i <- tryCatch(
      {
        Thermimage::readflirJPG(imagefile = file.names[i], 
                                exiftoolpath = exiftoolpath)
      },
      error = function(x){
        message(paste("Couldn't process file:",file.names[i]))
        return(NA)
      })

    # Flip the matrix (makes plotting later on easier)
    photo_i <- Thermimage::mirror.matrix(Thermimage::rotate180.matrix(photo_i))
    colnames(photo_i) <- NULL

    # Write the matrix to the appropriate index in the empty list
    raw_dat[[i]] <- photo_i
  }

  # Get camera parameters (constant for each camera)
  cat("Extracting camera parameters...","\n")
  camera_params <-
    Thermimage::flirsettings(imagefile = file.names[1],
                             exiftoolpath = exiftoolpath)

  # Reduce to parameters of interest
  camera_params <- data.frame(camera_params)
  camera_params <- camera_params[, grep("Info.Planck", names(camera_params))]
  colnames(camera_params) <- gsub("Info.", "", names(camera_params))

  # Write -------------------------------------------------------------------

  results <- list(raw_dat = raw_dat, camera_params = camera_params)

  if (write_results) {

    if (is.null(out_dir)) out_dir <- getwd()
    if (is.null(file_name)) file_name <- paste("flir_raw_", Sys.Date(),
                                               ".Rdata",sep = "")

    out_path <- file.path(out_dir, paste(file_name, ".Rdata", sep = ""))
    save(results,file = out_path)
  }

  return(results)
}





