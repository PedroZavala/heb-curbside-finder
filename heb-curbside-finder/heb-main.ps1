param([int]$zip=0, [int]$rds=0)

#To fetch nearest stores near zip code and trigger a script per store
#to check earliest available curbside pickup times.

$Host.UI.RawUI.WindowTitle = "Main"

function Logger([string]$msg) 
{
	$date = Get-Date -Format "MM-dd-yyyy HH:mm:ss.fff"
	Write-Host "["$date"]" $msg
}

#Allows scripts to run in this session
Set-ExecutionPolicy RemoteSigned

#For some reason this helps activate Invoke-RestMethod protocols
Logger -msg "Invoking https://google.com request to configure network protocols..."
$triggerPolicy = Invoke-RestMethod -Method Get -Uri "https://google.com"

#Creating app.log
$appLogFile = ".\app.log"
If (-not(Test-Path $appLogFile))
{
	$msg = "Creating new app log file..."
	Logger -msg $msg
	New-Item $appLogFile
}

Logger -msg "Configuring variables..."

$storesByZipUrl = "https://www.heb.com/commerce-api/v1/store/locator/address"
$apiBody = "{ ""address"": ""$zip"", ""curbsideOnly"": true, ""radius"": $rds, ""nextAvailableTimeslot"": true, ""includeMedical"": false }"

#Execute API
Logger -msg "Executing API..."
$storesNearby = Invoke-RestMethod -Method Post -Uri $storesByZipUrl -Body $apiBody -ContentType "application/json"
Logger -msg "Request successful."

#Parse return object for store Id's
Logger -msg "Now parsing return object for store Id's..."
$storeCount = [int]$storesNearby.stores.Length

#Print out the stores within the given radius
$msg = "Found " + $storeCount + " stores within a " + $rds + " mile radius."
Logger -msg $msg

If ($storeCount -gt 0) {
	#Adding job info to log
	$msg = "Executed Job in Zip: [" + $zip + "] Radius: [" + $rds + "] StoresFound: [" + $storeCount + "]"
	Add-Content -Path $appLogFile -Value $msg
	
	while ($storeCount -gt 0) { 	
		$storeCount = $storeCount - 1;
		$storeObj = $storesNearby.stores[$storeCount - 1].store;
		
		$storeId = [int]$storeObj.id
		$storeName = [string]$storeObj.name -replace " ", "-"
		$shortZip = [string]$storeObj.postalCode.SubString(0, 5)
		
		$msg = "Store ID:" + $storeId + " | Name: " + $storeName + " | Address: " + $storeObj.address1 + " " + $storeObj.city + " " + $shortZip
		Logger -msg $msg	
		
		$msg = "Now executing a job for store " + $storeId
		Logger -msg $msg
		
		#Creating new file for subscriber list
		$newFile = ".\subscribers\" + $shortZip + ".txt"
		If (-not(Test-Path $newFile))
		{
			$msg = "Creating new file for Zip: " + $shortZip
			Logger -msg $msg
			New-Item $newFile
		}
		
		Write-Host $PSScriptRoot
		
		$params =  "-storeId $storeId -storeZip ""$shortZip"" -storeName ""$storeName"""	
		$execute = "$PSScriptRoot\heb-store.ps1 " + $params
		
		$msg = "Execuing Command: " + $execute
		#Logger -msg $msg
			
		Start-Process -FilePath "powershell" -ArgumentList $execute
	}
}


#PZ :)