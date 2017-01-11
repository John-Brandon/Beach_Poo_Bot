## Beach Poo Bot

---

This TwitterBot downloads and processes San Francisco Bay and Ocean Beach water quality data. It does this twice a day, at 0700 and 1500 hrs (Pacific Time).

After downloading the data, the bot compares the latest time-date stamp with that from the previous download, and thus determines if a new sample has been posted. 

If a new sample has been posted, the bot tweets the data (i.e. *E. coli* counts per 100ml). The bot does not tweet if no new samples have been posted since the previous download.

The main code for the bot is written in R. The program can be scripted by executing `rShellScript.sh` in Bash (you'll likely need to edit the *.sh file to include your Rscript path, etc.).   

Currently, the bot is automated using a \*.plist file running on Mac OS.  The \*.plist file is written in XML. The freely available Mac OS LaunchControl GUI application can be used to write the automated run times in XML to the \*.plist. I haven't done this on Linux, but I think you'd want to write task times to a `chron` job file.     

@BeachPooBot was born into the wild on 2016-03-19 14:05:37 (local time), in Pacifica, CA. It has been searching and downloading data logs daily since then (see ./data/*csv). Further, it has been a more cooperative child to John than his other two (whom he manages to adore regardless).  
