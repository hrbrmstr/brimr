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
  res <- lapply(res, jsonlite::fromJSON, simplifyVector=TRUE, simplifyDataFrame = FALSE, simplifyMatrix = FALSE)

  class(res) <- c("brim_search_results", "list")

  res

}

#' @rdname brim_search
#' @param x a `brim_search_result` object
#' @param ... unused
#' @export
print.brim_search_results <- function(x, ...) {

  stats <- x[[which(sapply(x, function(.x) .x$type == "SearchStats"))]]
  as.numeric(
    as.POSIXct(stats$update_time$sec, origin = "1970-01-01") -
      as.POSIXct(stats$start_time$sec, origin = "1970-01-01"), "secs"
  ) -> delta

  cat(
    "ZQL query took ", scales::comma(delta, accuracy = 0.0001), " seconds", "; ",
    scales::comma(stats$records_matched), " records matched", "; ",
    scales::comma(stats$records_read), " records read", "; ",
    scales::comma(stats$bytes_read), " bytes read", "\n", sep = ""
  )

}

# TODO: Handle array, set, enum, union,
process_record <- function(aliases, schema, value) {

  nam <- schema[["name"]]
  typ <- schema[["type"]]
  typ <- ifelse(is.na(aliases[typ]), typ, aliases[typ])

  switch(
    typ,
    record = mapply(function(sch, val) {
      process_record(aliases, sch, val)
    }, schema[["of"]], value),

    null = set_names(NA, nam),
    bstring = set_names(list(value), nam),
    uint8 = set_names(as.integer(value), nam),
    uint16 = set_names(as.integer(value), nam),
    uint32 = set_names(as.integer(value), nam),
    uint64 = set_names(as.integer(value), nam),
    int8 = set_names(as.integer(value), nam),
    int16 = set_names(as.integer(value), nam),
    int32 = set_names(as.integer(value), nam),
    int64 = set_names(as.integer(value), nam),
    time = set_names(anytime::anytime(value), nam),
    duration = set_names(as.numeric(value), nam),
    float16 = set_names(as.numeric(value), nam),
    float32 = set_names(as.numeric(value), nam),
    float64 = set_names(as.numeric(value), nam),
    decimal = set_names(as.numeric(value), nam),
    bool = set_names(as.logical(value), nam),
    ip = set_names(as.character(value), nam),
    net = set_names(as.character(value), nam)#,
    # net = set_names(list(ipaddress::as_ip_network(value)), nam),
    # ip = set_names(list(ipaddress::as_ip_address(value)), nam)
  )

}

#' Turn Brim/zqd search results into a data frame
#'
#' @param x Brim/zqd search results
#' @export
tidy_brim <- function(x) {

  records <- x[[which(sapply(x, function(.x) .x$type == "SearchRecords"))]][["records"]]

  aliases <- data.frame(name = character(0), type = character(0))

  rbind.data.frame(
    aliases,
    do.call(rbind.data.frame, lapply(records[which(sapply(records, hasName, "aliases"))], function(.x) as.data.frame(.x$aliases)))
  ) -> aliases

  aliases <- set_names(aliases$type, aliases$name)

  schemas <- list()

  for (rec in records[which(sapply(records, hasName, "schema"))]) {
    schemas[[as.character(rec$id)]] <- rec$schema
  }

  lapply(records[which(sapply(records, hasName, "values"))], function(.x) {
    process_record(aliases, schemas[[as.character(.x$id)]], .x[["values"]])
  }) -> tmp

  lapply(tmp, function(.x) {
    do.call(cbind.data.frame, lapply(.x, function(.y) {
      if (!is.list(.y)) as.list(.y) else .y
    }))
  }) -> tmp

  tmp <- do.call(rbind.data.frame, tmp)

  tmp

}
