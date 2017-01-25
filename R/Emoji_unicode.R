# Retrieve unicode for emojis
#
# Testing emojis through R
# For emoji aliases, see:
# http://www.webpagefx.com/tools/emoji-cheat-sheet/
#
library(emojifont)  # Helper emoji functions
library(tidyverse)  # For Pipes %>% in R

# Create a list of possible emojis in unicode
eyes_emoji_uni = emoji("eyes")

hot_emoji_uni = emoji('hotsprings')

microscope_emoji_uni = search_emoji('microscope') %>%
  unique() %>%
  emoji()

warning_emoji_uni = search_emoji('warning') %>%
  emoji()

no_entry_emoji_uni = search_emoji('no_entry_sign') %>%
  emoji()

scream_emoji_uni = search_emoji('scream')[1] %>% emoji()

bangbang_emoji_uni = search_emoji('bangbang') %>%  # "!!" Seems to work with Twitter.
  unique() %>%
  emoji()

skull_emoji_uni = search_emoji("skull") %>%
  unique() %>%
  emoji()

# swimmer_emoji_uni = search_emoji('swimmer') %>%
#   unique() %>%
#   emoji()
#
# search_emoji('surfer') %>%
#   unique() %>%
#   emoji()

check_mark_emoji_uni = search_emoji("white_check_mark") %>%
  unique() %>%
  emoji()

red_circle_emoji_uni = search_emoji("red_circle") %>%
  unique() %>%
  emoji()

white_circle_emoji_uni = search_emoji("white_circle") %>%
  unique() %>%
  emoji()
