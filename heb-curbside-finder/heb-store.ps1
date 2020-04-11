param([int]$storeId=0, [string]$storeZip="", [string]$storeName="")

#To periodically check earliest H-E-B curbside pickup times and notify user/users in some fashion.

$msg = $storeZip + " | " + $storeName
$Host.UI.RawUI.WindowTitle = $msg

$daysAhead = 15
$curbSideSlotsUrl = "https://www.heb.com/commerce-api/v1/timeslot/timeslots?store_id=" + $storeId + "&days=" + $daysAhead + "&fulfillment_type=pickup"

function Logger([string]$msg) 
{
	$date = Get-Date -Format "MM-dd-yyyy HH:mm:ss.fff"
	Write-Host "["$date"]" $msg
}

function Send-ToEmail([string]$body, [string]$sub) 
{
    $message = new-object Net.Mail.MailMessage;
    $message.From = "me@earth.com";
    $message.Subject = "DO NOT REPLY | " + $storeName + " | " + $storeZip + " | Curbside Timeslots Available!";
    $message.Body = $body;
	$message.To.Add($sub);
	
	#setup email client
	$encrypted = Get-Content ".\token" | ConvertTo-SecureString;
	$email = Get-Content ".\relay-email"

    $smtp = new-object Net.Mail.SmtpClient("smtp.gmail.com", 587);
    $smtp.EnableSSL = $true;
    $smtp.Credentials = New-Object System.Net.NetworkCredential($email, $encrypted);
    $smtp.send($message);
	
	$msg = "Mail sent to: " + $sub
    Logger -msg $msg; 
}

function Send-Notification-To-Subs([string]$body)
{
	#Fetching subscriber list
	$subPath = ".\subscribers\" + $storeZip + ".txt"
	$subscribers = Get-Content -Path $subPath
	
	If ($subscribers.Count -gt 0)
	{
		$msg = "Found " + $subscribers.Count + " subscribers"
		Logger -msg $msg
		
		Logger -msg "Sending notifications..."
		$subscribers | ForEach-Object {
			Send-ToEmail -body $body -sub $_
		}
	}
	else
	{
		Logger -msg "No subscribers found. Aborting sending notification."
	}
}

#Input validation
If ($storeId -eq 0) 
{
	Logger -msg "Store Id is invalid. Exiting..."
	Start-Sleep -s 5
	exit 1
}
If ($storeZip.Length -eq 0) 
{
	Logger -msg "Store Zip code is invalid. Exiting..."
	Start-Sleep -s 5
	exit 1
}
If ($storeName.Length -eq 0) 
{
	Logger -msg "Store Name is invalid. Exiting..."
	Start-Sleep -s 5
	exit 1
}

#Start Job
$msg = "--- JOB FOR STORE ID: [" + $storeId + "] NAME: [" + $storeName + "] ZIP: [" + $storeZip + "] ---"
Logger -msg $msg

while (1 -eq 1)
{
	$msg = "Executing API: " + $curbSideSlotsUrl
	Logger -msg $msg
	
	$timeSlots = Invoke-RestMethod -Method Get -Uri $curbSideSlotsUrl
	$storesAvailable = ""
	
	$daysCount = $daysAhead
	$msg = "Now searching for next " + $daysCount + " day availability..."
	Logger -msg $msg
	$itemCount = $timeSlots.items.Count
	
	$msg = "Found " + $itemCount + " timeslots available"
	Logger -msg $msg
	
	$currDay = Get-Date -Format "yyyy-MM-dd"
	$nextDay = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")	
	$daysToCheck = @($currDay, $nextDay)
	
	while ($daysCount -gt 2) {
		$newDay = (Get-Date).AddDays($daysCount).ToString("yyyy-MM-dd")
		$daysToCheck += $newDay
		$daysCount -= 1
	}
		
	#Verify store has available timeslot within the next few days	
	If ($itemCount -gt 0) 
	{		
		Logger -msg "Parsing for availability on timeslots..."

		while ($itemCount -gt 0)
		{		
			$itemCount = $itemCount - 1
			$itemObj = $timeSlots.items[$itemCount]
			
			$daysToCheck | ForEach-Object {
				If ($itemObj.timeslot.date -contains $_)
				{					
					$msg = "Date: [" + $_ + "] Time: [" + $itemObj.timeslot.from_time + "]"
					Logger -msg $msg
					
					$storesAvailable = $storesAvailable + $msg + [Environment]::NewLine
				}
			}
		}
		
		Logger -msg "Parsing completed."

		#Send notification when availability exists
		If ($storesAvailable.Length -gt 0)
		{
			Send-Notification-To-Subs -body $storesAvailable
		}		
	}
	else
	{	
		Logger -msg "No time slots available at this time."	
	}
	
	$sleepTime = Get-Content ".\sleep-time"
	$sleepTime = [int]$sleepTime
	
	$msg = "Retrying in " + $sleepTime/60 + " minutes..."
	Logger -msg $msg
	Start-Sleep -s $sleepTime
}


#PZ :)