## Beach Poo Bot :poop:

---

### Bio :umbrella:
@BeachPooBot was born into the wild on 2016-03-19 14:05:37 (local time), in Pacifica, CA. It has been processing data logs daily since then -- tweeting fecal counts, as they are updated, for Ocean Beach, San Francisco. 

For a recent raw data set, dating back to 2015-12-21, and containing all associated sampling locations (including SF Bay), see the time series of `\*.csv` files in BeachPooBot's data directory.

### Technical details :ocean:
This TwitterBot downloads and processes San Francisco Bay and Ocean Beach water quality data from the SF Water Power Sewer web server. It does this twice a day, at 0700 and 1500 hrs (Pacific Time).

After downloading the data, the bot compares the latest time-date stamp with that from the previous download, and thus determines if a new sample has been posted. 

If a new sample has been posted, the bot tweets the updated data (i.e. *E. coli* counts per 100ml). The bot does not tweet if no new samples have been posted since the previous download.

The main code for the bot is written in `R`. See the code files `./R/ScrapePoo.R` (data processing) and `./R/TweetShit.R` (to interface with Twitter API).  

The program can be scripted in Bash by executing `./R/rShellScript.sh` (to replicate this, you'll likely need to edit the `\*.sh` file to include your `Rscript` path, etc.).   

Currently, the bot is automated using a `\*.plist` file running on Mac OS 10.11.6.  The `\*.plist` file is written in `XML`. The freely available Mac OS LaunchControl GUI application can be used to write the automated run times in `XML` to the `\*.plist`. A global Launch Agent is run on my Mac OS via `/Library/LaunchAgents/com.rTask.plist`. The `XML` for that file is shown below:

```XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.rTask</string>
	<key>Program</key>
	<string>/Users/johnbrandon/documents/R_hobby/BeachWater/R/rShellScript.sh</string>
	<key>RunAtLoad</key>
	<true/>
	<key>StandardErrorPath</key>
	<string>/tmp/com.rTask.err</string>
	<key>StandardOutPath</key>
	<string>/tmp/com.rTask.out</string>
	<key>StartCalendarInterval</key>
	<array>
		<dict>
			<key>Hour</key>
			<integer>7</integer>
			<key>Minute</key>
			<integer>0</integer>
		</dict>
		<dict>
			<key>Hour</key>
			<integer>15</integer>
			<key>Minute</key>
			<integer>0</integer>
		</dict>
	</array>
</dict>
</plist>
```


