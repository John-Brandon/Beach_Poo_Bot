#!/usr/bin/env Rscript
# TweetShit.R
# Author:     John R. Brandon, PhD
# Purpose:    Tweet water quality data (coliform levels) from SF Water Power
#             Sewer website
# Notes:      ScrapePoo.R does the heavy lifting. See the comments in that
#             file for more details re: scraping, logging etc.
#
# Copyright 2018 John R. Brandon
# This program is distributed under the terms of the GNU General Public License v3
# (provided in the ../LICENSE file).

# install.packages("twitteR")
library("twitteR")  # R interface with Twitter API

rm(list = ls())     # Clear workspace
print(Sys.time())   # Written to stdout log file as a check.

# Run scripts to access data from API ------------------------------------------
# The Bash rShellScript.sh starts in ./BeachWater directory (e.g. ~/BeachWater)
# The R source codes (and Bash script) are under ./BeachWater/R
source("./R/ScrapePoo.R")
source("./R/GetBeachStatus.R")

# Credentials ------------------------------------------------------------------
# Consumer Key (API Key)	wOGaeEQzlUbYZW2iagxgY8IOH
api_key = "wOGaeEQzlUbYZW2iagxgY8IOH"

# Consumer Secret (API Secret)	hnIHppfM1mvbHqs8S1UnaeZU0OFHI7F2xVwGYOe8hGBRnIApG6
api_secret = "hnIHppfM1mvbHqs8S1UnaeZU0OFHI7F2xVwGYOe8hGBRnIApG6"

# Access Token	710199368561860608-7PSV44DgI7Io4rgd3cbcis9ykRMVUbz
access_token = "710199368561860608-7PSV44DgI7Io4rgd3cbcis9ykRMVUbz"

# Access Token Secret	ctrg9lKQ3dxqfFSdlnNqeybZqjQy3GZd2dhf9C7jKKaMU
access_secret = "ctrg9lKQ3dxqfFSdlnNqeybZqjQy3GZd2dhf9C7jKKaMU"

# Set up OAuth credentials for a twitteR session -------------------------------
setup_twitter_oauth(consumer_key = api_key,
                    consumer_secret = api_secret,
                    access_token = access_token,
                    access_secret = access_secret)

# Send any updated E.coli sample tweets ----------------------------------------
if(length(all_tweets) > 0)
  map(.x = all_tweets, .f = twitteR::tweet)

# If sewer-overflow/posting status updated tweet list --------------------------
if(sewer_status_updated)
  map(.x = tweet_post_list, .f = twitteR::tweet)

# Exit message to stdout log file ----------------------------------------------
print("all_tweets")
print(all_tweets)
print("tweet_post_list")
print(tweet_post_list)
print("")
print("Exiting TweetShit")
print(Sys.time())   # Written to stdout log file as a check.
