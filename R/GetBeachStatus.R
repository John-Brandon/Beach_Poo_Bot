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

# Scrape beach status for a given sampling location ----------------------------
get_beach_status = function(beach_name, url){
  # Beaches should be posted as "Open" or "Closed".
  # Code has been tested for Ocean Beach locations to Crissy Field.
  # Bayside location confirmations would be good.
  # Used SelectorGadget browser plug-in to manually ID css_selector with beach status.
  # See also: https://blog.rstudio.org/2014/11/24/rvest-easy-web-scraping-with-r/
  css_selector = "table:nth-child(7) td"
  posted_status = read_html(url) %>%
                  html_node(css = css_selector) %>%
                  html_text() %>%
                  gsub(pattern = "\r", replacement = "") %>%
                  gsub(pattern = "\n", replacement = "") %>%
                  strsplit(split = ":", fixed = TRUE) %>%
                  unlist()
  paste(beach_name, posted_status[2], sep = ":")
}

# Create vector of sampling location URLs --------------------------------------
location_urls = c(
  Sloat = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4602",
  Lincoln = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4605",
  Balboa = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4604",
  "China Beach" = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4607",
  "Crissy Field W" = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4611",
  "Crissy Field E" = "https://sfwater.org/cfapps/LIMS/beachresults3.cfm?loc=4612"
)
location_names = names(location_urls)

# Use `purrr` package
# Mapping parallel elements of vector arguments to the function get_beach_status
location_status = map2_chr(location_names, location_urls, get_beach_status)

# Collapse into one string (tweet) with "\n" newline characters
status_tweet = paste(location_status, collapse = "\n", sep = "")
status_tweet = paste(status_tweet, sep = "")


#
# This code is a work in progress -- more involved than I thought at first.
# Download image with map of sampling locations --------------------------------
# get_imgsrc = function(url, node){
#   # Retrieve source of node (e.g. "/maps/beach_map_northpoint.png")
#   read_html(url) %>%
#     html_node(css = node) %>%
#     html_attr('src')
# }
#
# root_url = "http://www.sfwater.org/cfapps/lims"
# root_url = "http://www.sfwater.org/cfapps"
# main_url = "http://www.sfwater.org/cfapps/lims/beachmain1.cfm"
#
# node_sf = 'div+ img'  # Background map of SF
#
# foo = get_imgsrc(url = main_url, node = node_tmp)
# download.file(url = foo, destfile = basename(foo), method = "curl")
# system(paste("open", basename(foo)))
#
# # Download map of SF -----------------------------------------------------------
# map_src = read_html(main_url) %>%
#   html_node(css = node_sf) %>%
#   html_attr('src')
#
# map_url = paste(root_url, map_src, sep = "/")
# download.file(url = map_url, destfile = "foo.png", method = "curl")

