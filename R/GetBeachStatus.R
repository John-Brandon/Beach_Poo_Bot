# GetBeachStatus.R
#
# Tasks:
#   1. Scrape location posted status from webpage.
#   2. Download image file showing map and sampling locations.
#      This second task is a work in progress. The map of sampling locations
#      is rendered from multiple images in the html, which complicates
#      reverse engineering the map showing sampling locations.
#
# Motivation:
#   1. Augment information that can be be tweeted.
#
# Copyright 2016 John R. Brandon
# This program is distributed under the terms of the GNU General Public License v3
# (provided in the LICENSE file of this repository).
# ----------------------------------------------------------------------
library(rvest)  # Web scraping
library(purrr)  # Map along vector(s) of inputs to function calls (split-apply-combine)
library(tidyverse)  # Includes pipes %>% in R
library(magrittr)   # Bi-directional pipes %<>%

source("./R/Emoji_unicode.R")  # Returns a set of emoji unicode

# Scrape beach status for a given sampling location ----------------------------
get_beach_status = function(beach_name, url){
  # Beaches should be posted as "Open" or "Closed".
  # Code has been tested for Ocean Beach locations to Crissy Field.
  # Bayside location confirmations would be good.
  # Used SelectorGadget browser plug-in to manually ID css_selector with beach status.
  # See also: https://blog.rstudio.org/2014/11/24/rvest-easy-web-scraping-with-r/
  # On return, the posting status is prettified, eg blank first space removed
  css_selector = "table:nth-child(7) td"
  posted_status = read_html(url) %>%
                  html_node(css = css_selector) %>%
                  html_text() %>%
                  gsub(x = ., pattern = "\r", replacement = "") %>%
                  gsub(x = ., pattern = "\n", replacement = "") %>%
                  gsub(x = ., pattern = "^.", replacement = "") %>%
                  strsplit(split = ":", fixed = TRUE) %>%
                  unlist()
  posted_status[2]
}

check_sewer_status = function(url){
  # Scrape for Combined Sewer Overflow Status
  cs = "b"
  read_html(url) %>%
    html_node(css = cs) %>%
    html_text %>%
    unlist()  # return vector
}

merge_statuses = function(sewer_status, loc_status){
  # If not "Combined Sewer Overflow" status,
  # replace with location "Posted" or "Open" status
  if(is.na(sewer_status)){
    sewer_status = loc_status
  }
  sewer_status  # return
}

set_emoji = function(status){
  # Add emoji to latest beach status
  if(status == "Open"){
    emoj = ""  # If location posted as open, don't use emoji.
  }else if(status == "Posted"){
    emoj = warning_emoji_uni # red_circle_emoji_uni
  }else{  # "Sewer Overflow"
    emoj = paste(bangbang_emoji_uni, skull_emoji_uni, bangbang_emoji_uni)  #
  }
  paste(status, emoj, sep = "")  # Add corresponding emoji unicode to end of line
}

# Create vector of sampling location URLs --------------------------------------
location_urls = c(
  "Ft. Funston" = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4601",
  Sloat = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4602",
  Lincoln = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4605",
  Balboa = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4604",
  "China Bch" = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4607",
  "Baker Bch W" = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4608",
  "Crissy Fld W" = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4611",
  "Crissy Fld E" = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4612",
  "Aquatic P" = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4613",
  "Mission Crk" = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4618",
  "Islais Crk" = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4619",
  "Windsurfer Cir" = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4616"
)

# Create vector of sampling location names
location_names = names(location_urls)

# Scrape status "Posted" or "Open" for each location ---------------------------
# Uses `purrr` package and map function.
# Mapping parallel elements of vector arguments to the function get_beach_status.
location_status = map2_chr(location_names, location_urls, .f = get_beach_status) %>%
  gsub(x = ., pattern = "^.", replacement = "")  # Remove leading blank spaces

# Scrape Sewer Overflow Status -------------------------------------------------
# Inserts location status "Open" or "Posted" if sewer status not "Combined Sewer Overflow"
poo_status = map_chr(location_urls, check_sewer_status) %>%  # Scrape sewer status
  gsub(x =., pattern = "Combined ", replacement = "", fixed = FALSE) %>%  # Edit string
  map2_chr(., location_status, merge_statuses)  # Fill out statuses

# Check to see if status changed at ANY beach since last run -------------------

# Read vector with previous beach status from log file
previous_status = readLines("./data/location_status.out")

# Determine if updated status
refresh_status = any(previous_status != poo_status)
if (refresh_status) {
  # If status updated:
  # Concatinate location + status,
  # Collapse into a single string,
  # Add "\n" newline characters to format as a tweet.
  status_tweet = poo_status %>%
    map_chr(set_emoji) %>%  # add corresponding emoji
    paste(location_names, ., sep = ": ") %>%  # add location name
    paste(collapse = "\n")                    # new line between locations
} else {
  status_tweet = "The latest sample has not changed the posting status at Lincoln Way."
  # Insert list with posting status here (eg. "Lincoln: Open" "Balboa: Open" "Sloat: Open")
}

#
# Check to see if tweet > 140 characters. Split if too long. -------------------
#
if (nchar(status_tweet) > 140){
  # If all sampling sites have sewer overflow, there are too many characters.
  # As sampling locations have been added to the list, the status text will likely be > 140 regardless.
  # So, split into multiple strings (each with four sampling locations) for tweeting.

  # First split. Returns a character vector with two string elements.
  status_tweet %<>% strsplit(x = ., split = c("China Bch"), fixed = TRUE) %>% unlist()

  # Replace text that was destroyed by the strsplit function.
  status_tweet[2] = paste("China Bch", status_tweet[2], sep = "")

  # Second split
  status_tweet %<>% strsplit(x = ., split = c("Aquatic P"), fixed = TRUE) %>% unlist()

  # Replace text that was destroyed by the strsplit function.
  status_tweet[3] = paste("Aquatic P", status_tweet[3], sep = "")
}

# Write vector with each beach status to log file
write(x = poo_status, file = "./data/location_status.out", sep = "\n")
