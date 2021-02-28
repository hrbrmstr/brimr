#' Retrieve the Brim host URL
#'
#' Looks in the `BRIM_HOST` environment variable for the host
#' URL of the Brim instance to use for the API call. This
#' defaults to `http://127.0.0.1:9867`.
#'
#' @export
brim_host <- function() {
  Sys.getenv("BRIM_HOST", unset = "http://127.0.0.1:9867")
}

#' Turn a Brim ZQL query into an abstract syntax tree
#'
#' @param zql the ZQL query
#' @param host see [brim_host()]
#' @export
brim_ast <- function(zql, host = brim_host()) {

  httr::POST(
    url = sprintf("%s/ast", host),
    httr::content_type_json(),
    encode = "json",
    body = list(
      zql = zql
    )
  ) -> res

  httr::stop_for_status(res)

  invisible(httr::content(res, "text", encoding = "UTF-8"))

}

#' Retrieve active Brim spaces from the specified Brim instance
#'
#' @param host see [brim_host()]
#' @export
brim_spaces <- function(host = brim_host()) {

  httr::GET(
    url = sprintf("%s/space", host),
  ) -> res

  httr::stop_for_status(res)

  out <- httr::content(res, as = "text", encoding = "UTF-8")

  out <- jsonlite::fromJSON(out)
  class(out) <- c("tbl_df", "tbl", "data.frame")
  out

}

#' Post a ZQL query to the given Brim instance and retrieve results in raq ZJSON format
#'
#' @param space_name name of the Brim space to use as the search data source
#' @param zql the ZQL query
#' @param host see [brim_host()]
#' @export
brim_search_raw <- function(space_name, zql, host = brim_host()) {

  available_spaces <- brim_spaces()
  space_id <- available_spaces[available_spaces[["name"]] == space_name, "id", drop=TRUE]

  x <- sprintf('{"dir":-1,"proc":%s,"space":"%s"}', trimws(brim_ast(zql)), space_id)

  httr::POST(
    url = "http://127.0.0.1:9867/search",
    encode = "raw",
    httr::content_type_json(),
    query = list(
      format = "zjson"
    ),
    body = x
  ) -> res

  httr::stop_for_status(res)

  out <- httr::content(res, as = "text", encoding = "UTF-8")

  out

}

#' Post a ZQL query to the given Brim instance and retrieve processed results
#'
#' @param space_name name of the Brim space to use as the search data source
#' @param zql the ZQL query
#' @param host see [brim_host()]
#' @export
brim_search <- function(space_name, zql, host = brim_host()) {

  res <- brim_search_raw(space_name = space_name, zql = zql, host = host)
  res <- stringi::stri_split_lines(res, omit_empty = TRUE)
  res <- unlist(res)
  res <- lapply(res, jsonlite::fromJSON)

  invisible(res)

}