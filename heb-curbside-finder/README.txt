To execute a job per H-E-B store to look for the best available curbside pickup times.

# In order for e-mail to work you will need to configure an smtp server. I used a google account. 
# Next, you need to place that e-mail in the "relay-email" file. (If using g-mail, you need to enable non secure apps from accessing.)

#The password for that e-mail needs to be encrypted. Use powershell to generate a secure 
# token and place it in the file. Simple google search will show you how to do it. Then simply put that in the file "token".

#If you don't want e-mail simply comment out the e-mail calls.

To use execute heb-main.ps1 with parameters:
	-zip (The zip code you want to run jobs from)
	-rds (The radius in miles you want the search to execute)
	
	Ex: ".\heb-main.ps1" -zip 12345 -rds 1
	
	This will invoke a script per store. The file sleep-time should contain a single value, the time in seconds to sleep before checking times again.
	
To subscribe to e-mails, simply execute the script "heb-subscribe.ps1" and follow the prompts.