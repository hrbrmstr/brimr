#' Execute a zq command line
#'
#' zq is a command-line tool for processing logs. It applies boolean logic to
#' filter each log value, optionally computes analytics and transformations,
#' and returns results that can be consumed programmatically.\cr
#' \cr
#' This function takes command line arguments to be used with `zq` (
#' in the form [system2()] uses) and reads the results into a
#' data frame (it is actually a `data.table`).\cr
#' \cr
#' If the environment variable `ZQ_PATH` is not set or invalid, this function
#' will attempt to guess the `zq` binary path.\cr
#' \cr
#' Do not specify an output format as `-f ndjson` is added by default.
#'
#' @param args see [system2()]
#' @param parse if `TRUE` (the default) the output of the command line call
#'        will be parsed using [ndjson::stream_in()]. There are some combinations
#'        of `zq` flags that will never return ndjson output. There are heuristics
#'        in place to detect this, but you can deliberately force the function
#'        to return raw command line output by setting this to `FALSE`.
#' @return `data.table` (if output is parseable); character vector (if output is
#'         either not parseable or `parse` equals `FALSE`); or `NULL` in the
#'         event an error occurred when processing the `zq` command line.
#' @export
#' @examples
#' zq_cmd(
#'   c(
#'     '"* | cut ts,id.orig_h,id.orig_p"', # note the quotes
#'     system.file("logs", "conn.log.gz", package = "brimr")
#'    )
#'  )
zq_cmd <- function(args, parse = TRUE) {

  zq_path <- find_zq()

  if (is.na(zq_path)) {
    stop(
      "Cannot locate 'zq'. Please set the ZQ_PATH to the full path to the ",
      "executable or install Brim Desktop and/or zq.", call. = FALSE
    )
  }

  tf <- tempfile(fileext = ".json")
  on.exit(unlink(tf))

  system2(
    command = zq_path,
    args = c("-f ", "ndjson", args),
    stdout = tf
  ) -> res

  if (!is.null(res)) {

    one <- readLines(tf, 1)

    if ((parse) && grepl("\\{", one)) return(ndjson::stream_in(tf))

    readLines(tf)

  }

}
