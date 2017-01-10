## Beach Poo Bot

---

This TwitterBot downloads and processes San Francisco Bay and Ocean Beach water quality data. 

It does this twice a day, at 0700 and 1500 hrs (Pacific Time).

After downloading the data, the bot compares the latest time-date stamp with that from the previous download, and thus determines if a new sample has been posted. 

If a new sample has been posted, the bot tweets the data (i.e. *E. coli* counts per 100ml). The bot does not tweet if no new samples have been posted since the previous download.

The main code for the 'bot' is written in R. 

Currently, the bot is automated using a \*.plist file running on Mac OS.   


