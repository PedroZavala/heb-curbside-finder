#Used to unsubscribe from subscription list

$Host.UI.RawUI.WindowTitle = "Unsubscriber"

function Logger([string]$msg) 
{
	$date = Get-Date -Format "MM-dd-yyyy HH:mm:ss.fff"
	Write-Host "["$date"]" $msg
}

function Send-ToEmail([string]$body, [string]$sub) 
{
    $message = new-object Net.Mail.MailMessage;
    $message.From = "me@earth.com";
    $message.Subject = "DO NOT REPLY | Unsubscribed from H-E-B Curbside Locator!";
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

function Remove-Email([string]$email, [int]$zipCode, [int]$send) {
	$filePath = ".\subscribers\" + $zipCode + ".txt"
	$result = Get-Content -path $filePath
	
	If (Test-Path $filePath)
	{
		If ($result -contains $email) 
		{	
			If ($result.Count -eq 1) {
				$msg = "Clearing all content in file: " + $filePath + " since there was only a single email."
				Logger -msg $msg
				
				Clear-Content $filePath
				
				$msg = "Successfully removed E-mail: " + $email + " from Zip code: "  + $zipCode
				Logger -msg $msg
			}
			else {
				$result = $result | Where-Object { $_ -ne $email }
				$result | Set-Content $filePath
				
				$msg = "Successfully removed E-mail: " + $email + " from Zip code: "  + $zipCode
				Logger -msg $msg
				
				If ($send -eq 1) {
					Send-ToEmail -body $msg -sub $email
				}
			}
		}
		else
		{
			$msg = "E-mail: " + $email + " was not subscribed to Zip code: "  + $zipCode
			Logger -msg $msg
		}
	}
	else
	{
		Logger -msg "Subscriber list does not exist."
	}
}


$email = Read-Host -Prompt "Email"
while (-not($email -match ".+@.+.{3}")) 
{
	Logger -msg "Error: Must provide a valid email."
	$email = Read-Host -Prompt "Email"
}

$fromAll = Read-Host -Prompt "Unsubscribe from all mailing lists? (Y / N)"
If ($fromAll -eq "Y")
{
	#To remove email from every subscriber list
	$allFiles = Get-ChildItem -Path ".\subscribers" -Name
	If ($allFiles.Count -gt 0) {
		$allFiles | ForEach-Object {
			$zipCode = $_ -replace ".txt", ""
			Remove-Email -email $email -zipCode $zipCode -send 0
		}
		
		$msg = "Successfully removed from all mailing lists."
		Send-ToEmail -body $msg -sub $email
	}
	else {
		Logger -msg "No subscriber lists available to remove from."
	}
}
else
{
	#To remove subscriber from a single subscriber list
	$zipCode = Read-Host -Prompt "Zip Code"
	while (-not($zipCode -match "^\d{5}$")) 
	{
		Logger -msg "Error: Must provide a valid zip code."
		$zipCode = Read-Host -Prompt "Zip Code"
	}
	
	Remove-Email -email $email -zipCode $zipCode -send 1
}

Start-Sleep -s 5

#PZ :)