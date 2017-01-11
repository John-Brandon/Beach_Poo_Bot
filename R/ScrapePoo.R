# ScrapeWebData.R
# Author:     John R. Brandon, PhD
# Purpose:    Scrape water quality data (coliform levels) from SF Water Power
#             Sewer website
# Motivation: To the best of my knowledge, it isn’t possible to receive automatic
#             alerts (e.g. email updates) about beach closures at OB, San Francisco.
# Notes:
#
# List of sampling stations (not necessarily complete)
#
# BAY#202.4_SL, Crissy Field Beach East
# BAY#202.5_SL, Crissy Field Beach West
# BAY#210.1_SL, Hyde Street Pier
# BAY#211_SL, Aquatic Park
# BAY#220_SL, Mission Creek
# BAY#300.1_SL, Sunnydale Cove
# BAY#301.1_SL, Windsurfer Circle
# BAY#301.2_SL, Jackrabbit Beach
# BAY#320_SL, Islais Creek
# OCEAN#15EAST_SL, Baker Beach East
# OCEAN#15_SL, Baker Beach at Lobos Creek
# OCEAN#16_SL, Baker Beach West
# OCEAN#17_SL, China Beach
# OCEAN#18_SL, Ocean Beach at Balboa Street
# OCEAN#19_SL, Ocean Beach at Lincoln Way
# OCEAN#20_SL, Ocean Beach at Pacheco Street
# OCEAN#21_SL, Ocean Beach at Vicente Street
# OCEAN#21.1_SL, Ocean Beach at Sloat Boulevard
# OCEAN#22_SL, Fort Funston
#
# Copyright 2016 John R. Brandon
# This program is distributed under the terms of the GNU General Public License v3
# (provided in the LICENSE file).
#
library(ggplot2)   # Plotting
library(magrittr)  # For pipes, e.g. %>%
library(stringr)   # For regex (regular expression) to remove unwanted characters, etc.
library(devtools)  # For sourcing a snippet (gist) of code from GitHub
library(lubridate) # Dates and times
library(dplyr)     # For data wrangling

#
# Read Station ID keys from table ----------------------------------------------
#
station_key = read.csv("./data/station_key.csv", stringsAsFactors = FALSE)

#
# Download publically available data (*.csv) -----------------------------------
#
# Links through here:
#  https://data.sfgov.org/Energy-and-Environment/Beach-Water-Quality/uz7x-u572
# Seems regular sampling is done about once a week:
#  See also: http://sfwater.org/cfapps/lims/beachmain1.cfm

# Generate a temporary file name as recepticle for data file
temporaryFile = tempfile()

# Download data file into temporary file (admitedly convoluted, but it works)
download.file("http://sfwater.org/tasks/lims.csv",
              destfile = temporaryFile,
              method = "curl")

# Transfer temp data file into memory, and log time stamp
dat = read.csv(temporaryFile, stringsAsFactors = FALSE)
file.remove(temporaryFile)                # Remove temporary file
download_time = as.character(Sys.time())  # Timestamp

#
# Log data by writing to output file in ./data directory -----------------------
#
log_file = paste("./data/", "lims_", download_time, ".csv", sep = "")  # File name
write.csv(dat, file = log_file, row.names = FALSE)                     # Output *.csv

#
# Clean downloaded data --------------------------------------------------------
#
# as.Date makes this friendly for plotting
dat %<>% mutate(SAMPLE_DATE = as.Date(SAMPLE_DATE)) %>%
         filter(SOURCE != "") # remove any extraneous lines at end of file

# The DATA variable has some ">" and "<" prefix signs. Remove those using regex.
# Replace (remove) non-alphanumeric characters and convert DATA to numeric
dat %<>% mutate(DATA = str_replace_all(DATA, "[^[:alnum:]]", ""),
                DATA = as.numeric(DATA))

#
# Do a full join on the station_key and dat tables -----------------------------
#
# This should add a new column to the dat table, which has the full name of the
# ("SOURCE") sampling station associated with that ID. Otherwise station ID's
# are unintelligable.
dat %<>% full_join(station_key, dat, by = "SOURCE")

# Extract E.coli data from Lincoln Street
lincoln = dat %>% filter(name == "Ocean Beach at Lincoln Way") %>%
  filter(ANALYTE == "COLI_E")

lincoln_poo = lincoln$DATA[1]                              # Most recent E.coli count per 100 ml
sample_date = format(lincoln$SAMPLE_DATE[1], "%b %d, %Y")  # Most recent sample date, prettified
sample_location = lincoln$name[1]

#
# Compare most recent sample date with Log file --------------------------------
#
LogDateFile = "LastSampleDate.txt"
if(file.exists(LogDateFile)) {
  LastDate = scan(file = LogDateFile, nlines = 1, what = "character")
}

ymd_sample_date = mdy(sample_date)  # Coerce to class POSIXct (format: YYYY-MM-DD)

# If previously logged date is not equal to most recent date, continue processing
if (ymd_sample_date != ymd(LastDate)) {
  #
  # Log most recent sample date --------------------------------------------------
  #
  write.table(ymd_sample_date, file = LogDateFile,
              row.names = FALSE, col.names = FALSE) # , quote = FALSE

  #
  # ggplotting -------------------------------------------------------------------
  # Source R code from JB's GitHub for ggplotting with `mytheme_bw`
  # Use package devtools to load plot theme code with `source_gist`
  source_gist(id = "484d152675507dd145fe", sha1 = "eeb0f128acc6c50115a518ac0bda12800023484b")

  plt = ggplot(data = lincoln, aes(x = SAMPLE_DATE, y = DATA)) +
    geom_line(size = 1.25) + geom_point(size = 3.0) + mytheme_bw +
    labs(x ="Date", y = expression(italic("E. Coli  ")*"per 100 mL")) +
    ggtitle(paste(lincoln$name[1], sample_date, sep =": ")) +
    geom_hline(yintercept = 400, col = "red", lty = 2, size = 1.25)

  # Save time series plot to file
  string_today = as.character(today())  # Date stamp for file name
  plt_file_name = paste("timeseries_", string_today, ".png", sep = "")
  ggsave(filename = plt_file_name, plot = plt, device = "png")  # Save plot to file

  #
  # Create text for tweet --------------------------------------------------------
  #
  tweet_text = paste("Sample Date: ", sample_date, sep = "")
  tweet_text = paste(tweet_text, "; ", sample_location, sep = "")
  tweet_text = paste(tweet_text, "; ",
                     lincoln_poo, " parts E. coli per 100 mL.", sep = "")

  # Add text to tweet based on boolean assessment of whether at alert levels.
  if(lincoln_poo >= 400){
    tweet_text = paste("ALERT -- OCEAN BEACH LIKELY POSTED AS CLOSED -- ", tweet_text, sep = "")
  }else{
    tweet_text = paste(tweet_text, "; ", "Counts are less than 400 parts per 100 ml.", sep = "")
  }
}
