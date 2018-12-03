#!/usr/bin/env Rscript
# GetBeachStatus.R
#
# Tasks:
#   1. # Access status of sampling stations through SF's new API (updated ca. 2018), which
#   returns an JSON formatted data files.
#
# Motivation:
#   1. Augment information that can be be tweeted.
#
# Copyright 2018 John R. Brandon, PhD
# This program is distributed under the terms of the GNU General Public License v3
# (provided in the LICENSE file of this repository); available from:
#   https://github.com/John-Brandon/Beach_Poo_Bot
#
library(tidyverse)  # Includes pipes %>% in R
library(jsonlite)
library(RCurl)

source("./R/Emoji_unicode.R")  # Returns a set of emoji unicode

# Scrape beach status  ---------------------------------------------------------
xml_url = "https://infrastructure.sfwater.org/lims.asmx/getBeaches"
status_xml = RCurl::getURL(xml_url, encoding="XML")  # utf-8, gzip
status_xml = str_split(status_xml, pattern = '<')    # split into lists by comments
status_xml = status_xml[[1]][3]                      # remove some comments
status_xml = str_split(status_xml, pattern = '>')    # split into lists by comments
status_xml = status_xml[[1]][2]                      # extract JSON body (just the data)
status_dat = fromJSON(status_xml) %>% as.tibble()    # Parse JSON into data.frame
status_dat = status_dat %>%                          # Wrangle the data
  mutate(sample_date = as.Date(sample_date, format = '%m/%d/%y')) %>%
  mutate(status = case_when(
    is.na(cso) & is.na(posted) ~ 'Open',
    is.na(cso) & !is.na(posted) ~ 'Posted',
    !is.na(cso) ~ 'Sewer Overflow')
  )

tweet_post_dat = status_dat %>%
  left_join(station_key, by = c('stationname' = 'name')) %>%
  filter(tweet_post) %>%
  select(stationname, tweet_order, tweet_group, short_name, status) %>%
  mutate(tweet_text = map_chr(.x = status, .f = set_emoji)) %>%
  mutate(tweet_text = paste(short_name, tweet_text, sep = ': ')) %>%
         # tweet_text = paste(tweet_text, '\n', sep = '')) %>%
  arrange(tweet_order)

tweet_post_list = split(x = tweet_post_dat, f = tweet_post_dat$tweet_group) %>%
  unname() %>%
  map(.f = select, tweet_text) %>%
  map(pull) %>%
  map(paste, collapse = '\n')

# Check to see if status changed at ANY beach since last run -------------------
# Read vector with previous beach status from log file
previous_status = readLines("./data/location_status.out")  # could make this data.frame with names

# # Determine if updated status, and if so, compose status tweets
sewer_status_updated = any(previous_status != tweet_post_dat$status)

# Write vector with each beach status to log file
if(sewer_status_updated){
  write(x = tweet_post_dat$status, file = "./data/location_status.out", sep = "\n")
}
