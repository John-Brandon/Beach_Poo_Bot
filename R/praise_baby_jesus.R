#!/usr/bin/env RScript
# Lottery code for @BeachPooBot
# John R. Brandon
#
# set.seed(1946) # The U.S. President's birth year for reproducibility.
#
# Allegedly.
#
#
#
# install.packages("praise"); install.packages("magrittr")
library("praise")
library("magrittr")

this_and_that = paste("You are",
                      "${adverb_manner}",
                      "${adjective}",
                      "and",
                      "${adverb}",
                      "${created}",
                      "${EXCLAMATION}!")

for(i in 1:1e4) {
  praise(this_and_that) %>%
    paste(as.character(i), .) %>%
    cat(., "\n")
}

# Not tested
# lapply(FUN = tweet, X = this_and_that)

