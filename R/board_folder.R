#' Use a local folder as board
#'
#' @description
#' * `board_folder()` creates a board inside a folder. You can use this to
#'    share files by using a folder on a shared network drive or inside
#'    a DropBox.
#'
#' * `board_local()` creates a board in a system data directory. It's useful
#'    if you want to share pins between R sessions on your computer, and you
#'    don't care where the data lives.
#'
#' * `board_temp()` creates a temporary board that lives in a session
#'    specific temporary directory. It will be automatically deleted once
#'    the current R session ends. It's useful for examples and tests.
#'
#' @inheritParams new_board
#' @param path Path to directory to store pins. Will be created if it
#'   doesn't already exist.
#' @family boards
#' @examples
#' # session-specific local board
#' board <- board_temp()
#' @export
board_folder <- function(path, name = "folder", versioned = FALSE) {
  fs::dir_create(path)

  new_board_v1("pins_board_folder",
    cache = NA_character_,
    path = path,
    versioned = versioned
  )
}
#' @export
board_desc.pins_board_folder <- function(board, ...) {
  paste0("Path: '", board$path, "'")
}

#' @export
#' @rdname board_folder
board_local <- function(versioned = FALSE) {
  board_folder(rappdirs::user_data_dir("pins"), name = "local", versioned = versioned)
}

#' @rdname board_folder
#' @export
board_temp <- function(name = "temp", versioned = FALSE) {
  board_folder(fs::file_temp("pins-"), name = name, versioned = versioned)
}

# Methods -----------------------------------------------------------------

#' @export
pin_list.pins_board_folder <- function(board, ...) {
 fs::path_file(fs::dir_ls(board$path, type = "directory"))
}

#' @export
pin_exists.pins_board_folder <- function(board, name, ...) {
  as.logical(fs::dir_exists(fs::path(board$path, name)))
}

#' @export
pin_delete.pins_board_folder <- function(board, names, ...) {
  walk(names, check_name)
  fs::dir_delete(fs::path(board$path, names))

  invisible(board)
}

#' @export
pin_browse.pins_board_folder <- function(board, name, version = NULL, ..., cache = FALSE) {
  if (cache) {
    abort("board_local() does not have a cache")
  }
  meta <- pin_meta(board, name, version = version)
  browse_url(meta$local$dir)
}

#' @export
pin_store.pins_board_folder <- function(board, name, paths, metadata,
                                              versioned = NULL, ...) {
  check_name(name)
  version <- version_setup(board, name, metadata, versioned = versioned)

  version_dir <- fs::path(board$path, name, version)
  fs::dir_create(version_dir)
  write_meta(metadata, version_dir)
  fs::file_copy(paths, version_dir, overwrite = TRUE)

  invisible(board)
}

#' @export
pin_fetch.pins_board_folder <- function(board, name, version = NULL, ...) {
  pin_meta(board, name, version = version)
}

#' @export
pin_meta.pins_board_folder <- function(board, name, version = NULL, ...) {
  check_name(name)
  check_pin_exists(board, name)

  version <- version %||%
    last(pin_versions(board, name)$version) %||%
    abort("No versions found")

  path_version <- fs::path(board$path, name, version)
  if (!fs::dir_exists(path_version)) {
    abort(paste0("Can't find version '", version, "'"))
  }

  meta <- read_meta(path_version)
  local_meta(meta, dir = path_version, version = version)
}

#' @export
pin_versions.pins_board_folder <- function(board, name, ...) {
  check_name(name)
  check_pin_exists(board, name)

  paths <- fs::dir_ls(fs::path(board$path, name), type = "directory")
  version_from_path(fs::path_file(paths))
}

#' @export
pin_version_delete.pins_board_folder <- function(board, name, version, ...) {
  fs::dir_delete(fs::path(board$path, name, version))
}
