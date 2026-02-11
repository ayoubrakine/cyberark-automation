# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
##############################################################################################################

# Define a class to handle platform components
class PlatformHandler {

    # Declare a string variable to store the PVWA URL 
    [string] $pvwa_url

    # Constructor to initialize the class (not used in this script but present for flexibility)
    PlatformHandler() {}

    # Constructor to initialize the class with the PVWA URL
    PlatformHandler([string] $pvwa_url){
        $this.pvwa_url = $pvwa_url
    }
    
###################################### Get All Platforms ####################################################    

    # Method to retrieve all platforms    
    [PSCustomObject] getAllPlatforms([string] $auth_token){

        # Define the headers for the request, including the authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Construct the URL for the API endpoint to get all platforms
        $url = "https://$($this.pvwa_url)/PasswordVault/API/Platforms/"
        
        try {
            # Send a GET request to retrieve all platforms
            $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers
            # If the request is successful (HTTP 200 OK)
            if ($response.StatusCode -eq 200) {
                # Parse the JSON response content
                $parsedResponse = $response.Content | ConvertFrom-Json
                # Convert the parsed response to JSON format with a depth of 10
                $all_platforms = $($parsedResponse | ConvertTo-Json -Depth 10) 
                Write-Host "Retrieved all platforms successfully" -ForegroundColor Green
                [LogHandler]::Instance.LogWrite("Retrieved all platforms successfully.`n==========================================================")
                return $all_platforms
            } else {
                # If the request fails, display and log the error with the status code
                Write-Host "Retrieving all platforms failed. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("Retrieving all platforms failed. Returned Status code : $($response.StatusCode).`n==========================================================")
            }
        } catch {
            # Catch any exceptions during the request and log them
            Write-Host "An error occurred while retrieving all platforms : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving all platforms : $_.`n==========================================================")
        }
        return @()
}

###################################### Get Platforms Details ################################################

# Method to retrieve details of platforms from a CSV file
    [void] getPlatformsDetails([string] $auth_token) {

        # Prompt the user for the path to the CSV file containing platform names (IDs)
        $platformsToGetDetailsListPath=""
        do {
            $platformsToGetDetailsListPath = Read-Host "Please enter full path to your CSV file containing platform names (IDs)"

            if (-not (Test-Path $platformsToGetDetailsListPath)) {            
                Write-Host "CSV File path <$platformsToGetDetailsListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$platformsToGetDetailsListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $platformsToGetDetailsListPath))
        # Import the CSV file containing platform names (IDs)
        $platformsToGetDetailsList = Import-Csv $platformsToGetDetailsListPath -Delimiter ";"    
        Write-Host "CSV file imported successfully." -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any platform names (IDs)
        if ($platformsToGetDetailsList.Count -eq 0) {        
            Write-Host "No platform names found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No platform names found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each platform in the list
        foreach ($platform in $platformsToGetDetailsList) {

            try {
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Construct the URL for the API endpoint to get platform details
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Platforms/$($platform.platformName)/"
                # Send a GET request to retrieve details for the specified platform
                $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers
                # If the request is successful (HTTP 200 OK)
                if ($response.StatusCode -eq 200) {
                    # Convert the response content to a PowerShell object
                    $responseObject = $response.Content | ConvertFrom-Json
                    # Convert the PowerShell object back to JSON with proper formatting
                    $responseJson = $responseObject | ConvertTo-Json -Depth 10

                    Write-Host "Retrieved all details for platform : <$($platform.platformName)> completed successfully`n" -ForegroundColor Green
                    Write-Host "$responseJson"  
                    Write-Host "`n==========================================================`n" -ForegroundColor Green 
                    [LogHandler]::Instance.LogWrite("Retrieved all details for platform : <$($platform.platformName)> completed successfully.`n==========================================================")
                }
                else {
                    # If the request fails, display and log the error with the status code
                    Write-Host "Retrieving details for platform : <$($platform.platformName)> failed. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("Retrieving details for platform : <$($platform.platformName)> failed. Returned Status code : $($response.StatusCode).")                    
                }
                }
                catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while retrieving details for platform : <$($platform.platformName)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving details for platform : <$($platform.platformName)> : $_.`n==========================================================")                    
                }                
        }
        # Display a success message when all details are retrieved for all platforms
        Write-Host "Retrieving all details for all platforms from CSV file completed successfully" -ForegroundColor Green 
        [LogHandler]::Instance.LogWrite("Retrieving all details for all platforms from CSV file completed successfully.`n==========================================================")    
}

###################################### Import Platforms ######################################################

# Method to import platforms from a CSV file
    [void] importPlatforms([string] $auth_token){
        
        # Prompt the user to enter the full path to the CSV file containing platform names and zip file paths
        $platformsToImportListPath = Read-Host "Please Enter full path to your CSV file which contains platform names and zip file paths (separated with ';') "
        if (-Not (Test-Path $platformsToImportListPath)) {
                Write-Host "CSV file not found at path: $platformsToImportListPath" -ForegroundColor Yellow
                continue
        }
        # Import the CSV file containing platform names and zip file paths
        $platformsToImportList = import-CSV $platformsToImportListPath -Delimiter ";"     
        Write-Host "CSV file imported successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any platforms
        if ($platformsToImportList.Count -eq 0) {
            [LogHandler]::Instance.ErrorWrite("No platforms found in the CSV file. Please fill in the file and try again.`n==========================================================")
            Write-Host "No platforms found in the CSV file." -ForegroundColor Yellow
        }
        # Iterate through each platform in the list
        foreach ($platform in $platformsToImportList) {

            # Resolve the path to the ZIP file for the platform
            $zipPath = Resolve-Path -Path $platform.pathToZipFile            

            try {
                # Read the content of the ZIP file into a byte array
                $zipBytes = [System.IO.File]::ReadAllBytes($zipPath)
                # Encode the content in Base64
                $encodedZip = [System.Convert]::ToBase64String($zipBytes)
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Construct the URL for the API endpoint to import the platform
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Platforms/Import/"
                # Prepare the body of the request with the encoded ZIP file and platform name
                $body = @{
                    "ImportFile" = $encodedZip
                } | ConvertTo-Json -Depth 2

                try {
                    # Send a POST request to import the platform
                    $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                    # If the request is successful (HTTP 201 Created)
                    if( $response.StatusCode -eq 201) {
                        Write-Host "Importing platform <$($platform.platformName)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Importing platform <$($platform.platformName)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Importing platform <$($platform.platformName)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Importing platform <$($platform.platformName)> failed. Returned Status code : $($response.StatusCode).")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while importing platform <$($platform.platformName)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while importing platform <$($platform.platformName)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the file reading or encoding and log them
                Write-Host "An error occurred while importing platform <$($platform.platformName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while importing platform <$($platform.platformName)> : $_.`n==========================================================")
            }
        }
        # Display a success message when all platforms are imported from the CSV file
        Write-Host "Importing all platforms from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Importing all platforms from CSV file completed successfully.`n==========================================================")
    }

###################################### Export Platforms ######################################################

# Method to export platforms to ZIP files
    [void] exportPlatforms([string] $auth_token){

        # Define the script directory 
        $scriptDir = $PSScriptRoot
        # Define the parent directory
        $parentDir = Split-Path -Path $scriptDir -Parent
        # Define the export folder path
        $exportFolder = Join-Path $parentDir "SampleCSVFiles\SampleFilePlatform\Exported_Platform"
        # Check if the export folder exists, if not, create it
        if (-Not (Test-Path $exportFolder)) {
            New-Item -ItemType Directory -Path $exportFolder | Out-Null
            Write-Host "Creating export folder: $exportFolder" -ForegroundColor Cyan
        }
        # Prompt the user to enter the full path to the CSV file containing platform IDs
        $platformsToExportListPath = Read-Host "Please Enter full path to your CSV file which contains platform IDs "
        if (-Not (Test-Path $platformsToExportListPath)) {
                Write-Host "CSV file not found at path: $platformsToExportListPath" -ForegroundColor Yellow
                continue
        }
        # Import the CSV file containing platform IDs
        $platformsToExportList = import-CSV $platformsToExportListPath 
        Write-Host "CSV file imported successfully" -ForegroundColor Green
        Write-Host "`n--------------------------------------------------------------------------------------------" -ForegroundColor Cyan
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any platform IDs
        if ($platformsToExportList.Count -eq 0) {
            [LogHandler]::Instance.ErrorWrite("No platformID found in the CSV file. Please fill in the file and try again.`n==========================================================")
            Write-Host "No platformID found in the CSV file." -ForegroundColor Yellow
        }
        # Iterate through each platform in the list
        foreach ($platform in $platformsToExportList) {

            try {
                # Check if the platformID is provided
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Construct the URL for the API endpoint to export the platform
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Platforms/$($platform.platformID)/Export/"
                # Define the output ZIP file path using the platformID
                $outputZip = Join-Path $exportFolder "$($platform.platformID).zip"

                try {                
                    # Send a GET request to export the platform    
                    $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -OutFile $outputZip -UseBasicParsing -PassThru   
                    # If the request is successful (HTTP 200 OK)                 
                    if ($response.StatusCode -eq 200) {
                        Write-Host "Exporting platform <$($platform.platformID)> ...[OK]" -ForegroundColor Green
                        Write-Host "Exported platform <$($platform.platformID)> to $outputZip" -ForegroundColor Green
                        Write-Host "--------------------------------------------------------------------------------------------" -ForegroundColor Cyan
                        [LogHandler]::Instance.LogWrite("Exported platform <$($platform.platformID)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Exporting platform <$($platform.platformID)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Exporting platform <$($platform.platformID)> failed. Returned Status code : $($response.StatusCode).")
                    }
  
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while exporting platform <$($platform.platformID)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while exporting platform <$($platform.platformID)> : $_.`n==========================================================")
                }
            } catch {       
                # Catch any exceptions and log them         
                Write-Host "An error occurred while exporting platform <$($platform.platformID)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while exporting platform <$($platform.platformID)> : $_.`n==========================================================")
            }
        }    
        # Display a success message when all platforms are exported to ZIP files    
        Write-Host "Exporting all platforms completed successfully. Check the Exported Platform folder to find the ZIP files" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Exporting all platforms completed successfully. Check the Exported Platform folder to find the ZIP files.`n==========================================================")
    }
}    