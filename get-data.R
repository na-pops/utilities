get_data <- function(path)
{
  e <- new.env()
  name <- load(here::here(path), envir = e)[1]
  return(e[[name]])
}