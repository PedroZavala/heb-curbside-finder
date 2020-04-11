#To add subscribers per zip code

$Host.UI.RawUI.WindowTitle = "Subscriber"

function Logger([string]$msg) 
{
	$date = Get-Date -Format "MM-dd-yyyy HH:mm:ss.fff"
	Write-Host "["$date"]" $msg
}

function Send-ToEmail([string]$body, [string]$sub) 
{
    $message = new-object Net.Mail.MailMessage;
    $message.From = "me@earth.com";
    $message.Subject = "DO NOT REPLY | Now Subscribed to H-E-B Curbside Locator!";
    $message.Body = $body;
	$message.To.Add($sub);
	
	#setup email client
	$encrypted = Get-Content ".\token" | ConvertTo-SecureString;
	$email = Get-Content ".\relay-email";	

    $smtp = new-object Net.Mail.SmtpClient("smtp.gmail.com", 587);
    $smtp.EnableSSL = $true;
    $smtp.Credentials = New-Object System.Net.NetworkCredential($email, $encrypted);
    $smtp.send($message);
	
	$msg = "Mail sent to:";
    Logger -msg "Mail Sent";
}

do 
{
	Logger -msg "-- ADD SUBSCRIBER --"
	
	$email = Read-Host -Prompt "Email"
	while (-not($email -match ".+@.+.{3}")) 
	{
		Logger -msg "Error: Must provide a valid email."
		$email = Read-Host -Prompt "Email"
	}

	$zipCode = Read-Host -Prompt "Zip Code"
	while (-not($zipCode -match "^\d{5}$")) 
	{
		Logger -msg "Error: Must provide a valid zip code."
		$zipCode = Read-Host -Prompt "Zip Code"
	}

	$subPath = ".\subscribers\" + $zipCode + ".txt"
	If (-not(Test-Path $subPath)) 
	{
		Logger -msg "No jobs have been created for that zip code. Email will NOT be added to subscriber list."
	} 
	else 
	{
		$contents = Get-Content -Path $subPath
		If ($contents -contains $email) 
		{
			Logger -msg "Already subscribed!"
		} 
		else 
		{		
			Add-Content -Path $subPath -Value $email		
			$msg = "E-mail: [" + $email + "] now subscribed to job in Zip Code: [" + $zipCode + "]. To unsubscribe, let me know."
			Logger -msg $msg
			
			$send = Read-Host -Prompt "Send E-mail? (Y / N)"
			If ($send -eq "Y") 
			{
				Send-ToEmail -body $msg -sub $email
			}
		}
	}
	
	$response = Read-Host -Prompt "Add another subscriber? (Y / N)"
} 
while ($response -eq "Y")

#PZ :)