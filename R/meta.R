# i/o ---------------------------------------------------------------------

read_meta <- function(path) {
  path <- fs::path(path, "data.txt")

  if (!fs::file_exists(path)) {
    return(list(api_version = 1L))
  }

  yaml <- yaml::read_yaml(path, eval.expr = FALSE)
  if (is.null(yaml$api_version)) {
    yaml$api_version <- 0L
  } else if (yaml$api_version > 1) {
    abort(c(
      paste0("Metadata requires pins ", yaml$api_version, ".0.0 or greater"),
      i = "Do you need to upgrade the pins package?"
    ))
  }

  yaml
}

write_meta <- function(x, path) {
  path <- fs::path(path, "data.txt")
  write_yaml(x, path)
}

# pin metadata ------------------------------------------------------------

standard_meta <- function(path, type, object = NULL, desc = NULL) {
  list(
    file = fs::path_file(path),
    file_size = as.integer(fs::file_size(path)),
    pin_hash = pin_hash(path),
    type = type,
    description = desc %||% default_description(object, path),
    created = format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC"),
    api_version = 1
  )
}

as_8601_compact <- function(x = Sys.time()) {
  format(x, "%Y%m%dT%H%M%SZ", tz = "UTC")
}
parse_8601_compact <- function(x) {
  y <- as.POSIXct(strptime(x, "%Y%m%dT%H%M", tz = "UTC"))
  attr(y, "tzone") <- ""
  y
}

# description -------------------------------------------------------------

default_description <- function(object, path) {
  if (is.null(object)) {
    n <- length(path)
    if (n == 1) {
      desc <- glue("a .{fs::path_ext(path)} file")
    } else {
      desc <- glue("{n} files")
    }
  } else if (is.data.frame(object)) {
    desc <- glue("a data frame with {nrow(object)} rows and {ncol(object)} columns")
  } else {
    desc <- friendly_type(typeof(object))
  }

  paste0("A pin containing ", desc)
}

