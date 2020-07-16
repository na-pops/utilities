####### Script Information ########################
# Brandon P.M. Edwards
# NA-POPS: project-PROJECTNAME
# standardize-data.R
# Created July 2020
# Last Updated July 2020

####### Import Libraries and External Files #######

library(lutz)
library(here)
library(lubridate)

####### Set Constants #############################

project <- "PROJECTNAME"

####### Read Data #################################

data_all <- read.csv(here::here("rawdata", paste0("../rawdata/",
                                           project,
                                           "_raw.csv")))

####### Create Standard Counts File ###############

# Remove non-species
data_select <- data_all[which(data_all$SpeciesCode != "UNKN"), ]

# Create unique sample ID
sample_id <- paste0(data_select$ProjectCode, ":",
                    data_select$SamplingUnitId, ":",
                    data_select$ObservationDate, ":",
                    data_select$Time)

# Add it onto the original file, we'll use it later
data_select$sample_id <- sample_id

# Create distance interval column and bin distances
data_select$distance_method <- "C"
data_select$distance_level <- ifelse(data_select$DistanceFromObserver <= 50, 1, 2)

# Create time interval column and bin times
data_select$duration_method <- "A"
data_select$duration_level <- 1


# Put together the standardized point count data set
count_df <- data.frame(Sample_ID = data_select$sample_id,
                       Species = data_select$SpeciesCode,
                       Abundance = data_select$ObservationCount,
                       Distance_Method = data_select$distance_method,
                       Distance_Level = data_select$distance_level,
                       Exact_Distance = NA,
                       Duration_Method = data_select$duration_method,
                       Duration_Level = data_select$duration_level,
                       Flyover = data_select$Flyover)

write.table(count_df,
            file = here::here("output", paste0(project,
                                               "_counts.csv")),
            row.names = FALSE,
            sep = ",")

####### Create Sampling Lookup File ###############

# The point of one of these files is to eventually have them
#    all appended to each other as a master sampling
#    lookup file

data_unique <- data_select[!duplicated(data_select$sample_id), ]

# Get time zone
time_zone <- lutz::tz_lookup_coords(lat = data_unique$DecimalLatitude,
                                    lon = data_unique$DecimalLongitude,
                                    method = "fast")

utc_offset <- lutz::tz_offset(as.POSIXct(data_unique$ObservationDate), 
                              tz = time_zone[1])$utc_offset_h

date_time <- paste(data_unique$ObservationDate,
                   data_unique$Time)

utc_time <- hms(data_unique$Time) + hours(x = (-1)*utc_offset)
utc_formatted <- sprintf("%s:%s:%s", 
                         hour(utc_time), 
                         minute(utc_time), 
                         second(utc_time))

utc_formatted[utc_formatted == "NA:NA:NA"] <- ""

utc <- paste(data_unique$ObservationDate,
             utc_formatted)

sampling_df <- data.frame(Sample_ID = data_unique$sample_id,
                          Project_Code = data_unique$ProjectCode,
                          Date_Time = date_time,
                          UTC = utc,
                          Latitude = data_unique$DecimalLatitude,
                          Longitude = data_unique$DecimalLongitude)

write.table(sampling_df,
            file = here::here("output", paste0(project,
                                               "_samples.csv")),
            row.names = FALSE,
            sep = ",")
