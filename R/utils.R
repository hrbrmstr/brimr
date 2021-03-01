is_windows <- function() .Platform$OS.type == "windows"
is_mac     <- function() Sys.info()[["sysname"]] == "Darwin"
is_linux   <- function() Sys.info()[["sysname"]] == "Linux"

platform <- function() {
  if (is_windows()) return("win")
  if (is_mac())     return("mac")
  if (is_linux())   return("linux")
  stop("unknown platform")
}

set_names <- function (object = nm, nm) {
  names(object) <- nm
  object
}

version_test <- function(zq_path) {

  try(
    system2(
      command = zq_path,
      args = "-version",
      stdout = TRUE,
      stderr = TRUE
    ) ,
    silent = TRUE
  ) -> res

  ((is.null(attributes(res))) && any(grepl("Version", res)))

}

find_zq <- function() {

  try_env <- Sys.getenv("ZQ_PATH", unset = NA)

  if (is.na(try_env)) {
    if (is_mac()) {
      try_env <- "/Applications/Brim.app/Contents/Resources/app/zdeps/zq"
    } else if (is_linux()) {
      try_env <- "/usr/lib/brim/resources/app/zdeps/zq"
    }
  } # TODO Windows

  if (!file.exists(try_env)) try_env <- Sys.which("zq")

  if (file.exists(try_env)) {
    if (version_test(try_env)) return(try_env)
  }

  NA

}