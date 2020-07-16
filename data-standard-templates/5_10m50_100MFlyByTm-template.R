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

# Create unique sample ID by DATE ONLY (dealing with time bins now)
sample_id <- paste0(data_select$ProjectCode, ":",
                    data_select$SamplingUnitId, ":",
                    data_select$ObservationDate)
data_select$sample_id <- sample_id

# Determine time bins
# Unfortunately for this data set we have to make the assumption that if
#    it's only 1 time bin, that the observation happened in the first one
data_select$duration_method <- "B"
data_select$duration_level <- NA
for (s in unique(sample_id))
{
  rows <- which(data_select$sample_id == s)
  times <- unique(data_select[rows,]$Time)
  if (length(times) == 1)
  {
    data_select[rows, "duration_level"] <- 1
  }else
  {
    if (strptime(times[1], "%H:%M:%S") > strptime(times[2], "%H:%M:%S"))
    {
      times <- rev(times)
    }
    data_select[intersect(rows, which(data_select$Time == times[1])), "duration_level"] <- 1
    data_select[intersect(rows, which(data_select$Time == times[2])), "duration_level"] <- 2
  }
}

# Add the time on to sample id
data_select$sample_id <- paste0(sample_id, ":",
                                data_select$Time)

# Create distance interval column and bin distances
data_select$distance_method <- "B"
data_select$distance_level <- ifelse(data_select$DistanceFromObserver <= 50, 1, 2)
data_select[which(data_select$DistanceFromObserver > 100), "distance_level"] <- 3

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
                          Longitude = data_unique$DecimalLongitude,
                          Distance_Method = data_unique$distance_method,
                          Duration_Method = data_unique$duration_method)

write.table(sampling_df,
            file = here::here("output", paste0(project,
                                               "_samples.csv")),
            row.names = FALSE,
            sep = ",")
