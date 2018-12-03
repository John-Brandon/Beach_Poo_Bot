#!/usr/bin/env Rscript
# Access status of sampling stations through SF's new API (updated ca. 2018), which
#   returns an JSON formatted data files.
#
# Copyright 2018 John R. Brandon, PhD
# This program is distributed under the terms of the GNU General Public License v3
# provided in the LICENSE file of this repository; available from:
#   https://github.com/John-Brandon/Beach_Poo_Bot
library(tidyverse)  # for data wrangling and ggplotting
library(jsonlite)
library(RCurl)

# Read Station ID keys from table ----------------------------------------------
station_key = read.csv("./etc/station_key.csv", stringsAsFactors = FALSE) %>%
  as_tibble()

# Log data from server by writing to output file in ./data directory -----------
download_time = as.character(Sys.time())  # Timestamp
download_time = str_replace(download_time, pattern = " ", replacement = "_")

# Get sampling counts data: `lims` ---------------------------------------------
counts_url = 'https://infrastructure.sfwater.org/lims.asmx/getCSV'
counts_status = RCurl::getURL(counts_url)
counts_dat = jsonlite::fromJSON(counts_status) %>%
  as.tibble() %>%
  # select(-posted, -color, -cso)  %>%  # These columns are not populated (as of 2018-11-28)
  filter(!is.na(analyte)) %>%
  mutate(sample_date = as.Date(sample_date, format = '%m/%d/%y')) %>%
  # The DATA variable has some ">" and "<" prefix signs. Remove those using regex.
  mutate(data = str_replace_all(data, "[^[:alnum:]]", ""),
         data = as.numeric(data))

counts_dat  # Check
# A tibble: 687 x 7
# source       sample_date analyte     data posted color cso
# <chr>        <date>      <chr>      <dbl> <lgl>  <lgl> <lgl>
# 1 BAY#202.4_SL 2018-11-13  COLI_E        10 NA     NA    NA
# 2 BAY#202.4_SL 2018-11-13  COLI_TOTAL    10 NA     NA    NA

#
# Do a full join on the station_key and dat tables -----------------------------
#
# This should add a new column to the `counts_dat` table, which has the full name of the
# ("SOURCE") sampling station associated with that ID. Otherwise station ID's
# are unintelligable.
counts_dat = full_join(station_key, counts_dat, by = "source") %>%
  as_tibble()

# Plot correlation between total coliform and e.coli levels (log-log scale)
# counts_dat %>%
#   select(short_name, sample_date, analyte, data) %>%
#   # filter(!(name %in% c('Fort Funston', 'China Beach'))) %>%
#   filter(!is.na(short_name)) %>%
#   spread(key = analyte, value = data) %>%
#   # group_by(short_name) %>%
#   # arrange(analyte) %>%
#   ggplot(aes(x = log(COLI_E), y = log(COLI_TOTAL))) +
#   geom_point(size = 2, alpha = 0.5) +
#   geom_smooth(method = lm) +
#   facet_wrap(~short_name) +
#   geom_abline() +
#   xlab('Ln (E.coli)') +
#   ylab('Ln (Total Coliform Count)')

# Read locations to tweet from input file --------------------------------------
locs_to_tweet = readLines(con = "./etc/spots_to_tweet.txt")

# Group data by location(name)  ------------------------------------------------
# Query only those locations in `locs_to_tweet`
# Filter out only first row, which is the most recent sample
# Eventually want to check dates for each location, such
#   that only tweet if sample for given location is updated
locs_dat = counts_dat %>%
  group_by(name) %>%
  filter(name %in% locs_to_tweet,
         analyte == "COLI_E") %>%
  slice(1) %>%
  ungroup()

# locs_dat  # Check

# Read last sample date(s) from log file ---------------------------------------
log_date_file = "LastSampleDate.txt"
if(file.exists(log_date_file)) {
  last_date = read_csv(file = log_date_file, col_names = c('last_date', 'name'))
} else {
  stop('ERROR: File Not Found. LastSampleDate.txt')
}

date_dat = locs_dat %>%
  left_join(last_date, by = 'name') %>%
  mutate(updated = ifelse(sample_date > last_date, TRUE, FALSE))

# Create text for tweet ------------------------------------------------------
compose_tweet = function(sample_location, spot_count, sample_date){
  # Given sampling data for a location, compose and format a tweet
  paste0(sample_location, "\n",
         spot_count, " parts E. coli per 100 mL.", "\n",
         "Sample Date: ", sample_date)
}
# create vector with tweet of 'E.coli' levels for each location in `locs_to_tweet`
# note: can get NA values for `updated` here if number of `locs_to_tweet` increased
all_tweets = date_dat %>%
  filter(updated == TRUE | is.na(updated)) %>%
  mutate(tweet_txt = compose_tweet(sample_location = name,
                                   spot_count = data,
                                   sample_date = format(sample_date, '%b %d, %Y'))) %>%
  pull(tweet_txt)

# Log most recent sample date ------------------------------------------
#  Only do this if sample date has been updated
if(any(date_dat$updated)){
  locs_dat %>%
    select(sample_date, name) %>%
    write_csv(x = ., path = log_date_file, col_names = FALSE)
}

#
# ggplotting -----------------------------------------------------------------
# Source R code from JB's GitHub for ggplotting with `mytheme_bw`
# Use package devtools to load plot theme code with `source_gist`
#
# source_gist(id = "484d152675507dd145fe", filename = "mytheme_bw.R")
#
# plt = ggplot(data = lincoln, aes(x = SAMPLE_DATE, y = DATA)) +
#   geom_line(size = 1.25) + geom_point(size = 3.0) + mytheme_bw +
#   labs(x ="Date", y = expression(italic("E. Coli  ")*"per 100 mL")) +
#   ggtitle(paste(lincoln$name[1], sample_date, sep =": ")) +
#   geom_hline(yintercept = 400, col = "red", lty = 2, size = 1.25)
#
# # Save time series plot to file
# string_today = as.character(today())  # Date stamp for file name
# plt_file_name = paste("timeseries_", string_today, ".png", sep = "")
# ggsave(filename = plt_file_name, plot = plt, device = "png")  # Save plot to file
