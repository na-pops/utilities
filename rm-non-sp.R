# Removes all non-species that I missed during original filtering
rm_non_sp <- function(data = NULL)
{
  to_remove <- c("UNFL", "WEFL", "SAGS")
  data_rm <- data[-which(data$Species %in% to_remove), ]
  
  return(data_rm)
}