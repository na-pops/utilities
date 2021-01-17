order_taxo <- function(data = NULL)
{
  codes <- read.csv("../utilities/IBP-Alpha-Codes20.csv")$SPEC
  
  data_tax <- data[match(codes, data$Species), ]
  data_tax <- data_tax[!is.na(data_tax$Species), ]
  
  return(data_tax)
}