# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
##############################################################################################################

# Define a class to handle safes
class SafeHandler {

    # Declare a string variable to store the PVWA URL
    [string] $pvwa_url

    # Constructor to initialize the class (not used in this script but present for flexibility)
    SafeHandler() {}

    # Constructor to initialize the class with the PVWA URL
    SafeHandler([string] $pvwa_url){
        $this.pvwa_url = $pvwa_url
    }

###################################### Get All Safes ######################################################    

# Method to retrieve all safes
    [PSCustomObject] getAllSafes([string] $auth_token){

        # Define the headers for the request, including the authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Construct the URL for the API endpoint to get safes
        $url = "https://$($this.pvwa_url)/PasswordVault/API/Safes?includeAccounts=true"

            try {
                # Send a GET request to retrieve all safes
                $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers
                # If the request is successful (HTTP 200 OK)
                if( $response.StatusCode -eq 200){
                    # Parse the JSON response content
                    $parsedResponse = $response.Content | ConvertFrom-Json
                    $all_safes = $($parsedResponse | ConvertTo-Json -Depth 10)
                    Write-Host "Retrieved all safes successfully" -ForegroundColor Green
                    [LogHandler]::Instance.LogWrite("Retrieved all safes successfully.`n==========================================================")
                    return $all_safes
                } else {
                    # If the request fails, display and log the error with the status code
                    Write-Host "Retrieving safes failed. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("Retrieving safes failed. Returned Status code : $($response.StatusCode).")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred while retrieving safes : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving safes : $_.`n==========================================================")           
            }        
            # Return an empty PSCustomObject if no safes are found or if there was an error
            return [PSCustomObject]@{}
    }
    
###################################### Get Safes Details ######################################################   

# Method to retrieve details of a specific safe
    [PSCustomObject] getSafeDetails([PSCustomObject] $safe,[string] $auth_token) {

        # Define the headers for the request, including the authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Construct the URL for the API endpoint to get details of the specified safe
        $url = "https://$($this.pvwa_url)/PasswordVault/API/Safes/?search=$($safe.safeName)"
        
        try {
            # Send a GET request to retrieve details of the specified safe
            $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers
            # If the request is successful (HTTP 200 OK)
            if ($response.StatusCode -eq 200) {
                # Parse the JSON response content
                $response = ConvertFrom-Json $response
                # Iterate through the results to find the safe with the matching name
                foreach ($result_safe in $response.value) {
                    if ($result_safe.safeName -eq $safe.safeName) {
                        # If the safe is found, return its details
                        return $result_safe
                    }
                }
                # Account not found
                Write-Host "Safe <$($safe.safeName)> not found" -ForegroundColor Yellow
                [LogHandler]::Instance.ErrorWrite("Safe <$($safe.safeName)> not found.")
                # Return an empty PSCustomObject if the safe is not found
                return [PSCustomObject]@{}
            }
            else {
                # If the request fails, display and log the error with the status code
                Write-Host "Retrieving details for safe <$($safe.safeName)> failed. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("Retrieving details for safe <$($safe.safeName)> failed. Returned Status code : $($response.StatusCode).")
                return [PSCustomObject]@{}
            }
        }
        catch {
            # Catch any exceptions during the request and log them
            Write-Host "An error occurred while retrieving details for safe <$($safe.safeName)> : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving details for safe <$($safe.safeName)> : $_.`n==========================================================")    
            return [PSCustomObject]@{}
        }
    }

###################################### Add Safes #############################################################   

# This function adds safes based on the provided CSV file
    [void] addSafes([string] $auth_token){

        # Prompt the user for the path to the CSV file containing safes to add
        $safesToAddListPath=""
        do {
            $safesToAddListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $safesToAddListPath)) {            
                Write-Host "CSV File path <$safesToAddListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$safesToAddListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $safesToAddListPath))
        # Import the CSV file containing safes to add
        $safesToAddList = Import-Csv $safesToAddListPath -Delimiter ";"    
        Write-Host "`nCSV file imported successfully.`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any safes
        if ($safesToAddList.Count -eq 0) {        
            Write-Host "No safes found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No safes found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }

        # Iterate through each safe in the list
        foreach ($safe in $safesToAddList) {

            try {  
                # Prepare the data for the safe to be added              
                $safe_data = @{
                    "safeName" = $safe.safeName
                    "description" = $safe.description
                    "managingCPM" = $safe.managingCPM
                    "numberOfDaysRetention" = $safe.numberOfDaysRetention
                    "numberOfVersionsRetention" = $safe.numberOfVersionsRetention
                    "oLACEnabled" = $safe.oLACEnabled
                    "autoPurgeEnabled" = $safe.autoPurgeEnabled
                    "location" = $safe.location
                }
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Construct the URL for the API endpoint to add safes
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Safes/"
                # Convert the safe data to JSON format
                $body = $safe_data | ConvertTo-Json -Depth 10

                try {
                    # Send a POST request to add the safe
                    $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                    # If the request is successful (HTTP 201 Created)
                    if( $response.StatusCode -eq 201) {
                        Write-Host "Adding safe <$($safe_data['safeName'])> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Adding safe <$($safe_data['safeName'])> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Adding safe <$($safe_data['safeName'])> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Adding safe <$($safe_data['safeName'])> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while adding safe <$($safe.safeName)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while adding safe <$($safe.safeName)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred while adding safe <$($safe.safeName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while adding safe <$($safe.safeName)> : $_.`n==========================================================")
            }
        }
        # Display success message after processing all safes
        Write-Host "`nAdding all safes from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Adding all safes from CSV file completed successfully.`n==========================================================")
    }

###################################### Update Safes ###################################################### 

# This function updates existing safes based on the provided CSV file
    [void] updateSafes([string] $auth_token){
        
        # Prompt the user for the path to the CSV file containing safes to update
        $safesToDeleteListPath=""
        do {
            $safesToDeleteListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $safesToDeleteListPath)) {            
                Write-Host "CSV File path <$safesToDeleteListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$safesToDeleteListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $safesToDeleteListPath))
        # Import the CSV file containing safes to update
        $safesToDeleteList = Import-Csv $safesToDeleteListPath -Delimiter ";"    
        Write-Host "`nCSV file imported successfully.`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any safes
        if ($safesToDeleteList.Count -eq 0) {        
            Write-Host "No safes found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No safes found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each safe in the list
        foreach ($safe in $safesToDeleteList) {

            try {
                # Prepare the data for the safe to be updated
                $NewSafeData = @{
                        "safeName" = $safe.newSafeName
                        "description" = $safe.description
                        "managingCPM" = $safe.managingCPM
                        "numberOfDaysRetention" = $safe.numberOfDaysRetention
                        "numberOfVersionsRetention" = $safe.numberOfVersionsRetention
                        "oLACEnabled" = $safe.oLACEnabled
                        "autoPurgeEnabled" = $safe.autoPurgeEnabled
                        "location" = $safe.location
                }
                # Define the headers for the request, including the authorization token
                $headers = @{
                "Authorization" = $auth_token
                "Content-Type"  = "application/json"
                }
                # Get the details of the safe to be updated
                $safe_details = $this.getSafeDetails($safe, $auth_token)
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Safes/$($safe_details.safeUrlId)/"
                $body = $NewSafeData | ConvertTo-Json -Depth 10
                
                try { 
                    # Send a PUT request to update the safe                  
                    $response = Invoke-WebRequest $url -Method 'PUT' -Headers $headers -Body $body
                    # If the request is successful (HTTP 200 OK)
                    if( $response.StatusCode -eq 200) {
                        Write-Host "Updating safe <$($safe.safeName)> to <$($safe.newSafeName)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Updating safe <$($safe.safeName)> to <$($safe.newSafeName)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Updating safe <$($safe.safeName)> to <$($safe.newSafeName)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Updating safe <$($safe.safeName)> to <$($safe.newSafeName)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {    
                    # Catch any exceptions during the request and log them            
                    Write-Host "An error occurred while updating safe <$($safe.safeName)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while updating safe <$($safe.safeName)> : $_.`n==========================================================")
                }
            } catch {   
                # Catch any exceptions during the request and log them         
                Write-Host "An error occurred while updating safe <$($safe.safeName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while updating safe <$($safe.safeName)> : $_.`n==========================================================")
            }
        }
        # Display success message after processing all safes
        Write-Host "`nUpdating all safes from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Updating all safes from CSV file completed successfully.`n==========================================================")
    }

###################################### Delete Safes ###################################################### 

# This function deletes safes based on the provided CSV file
    [void] deleteSafes([string] $auth_token){
        

        # Prompt the user for the path to the CSV file containing safes to delete
        $safesToDeleteListPath=""
        do {
            $safesToDeleteListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $safesToDeleteListPath)) {            
                Write-Host "CSV File path <$safesToDeleteListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$safesToDeleteListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $safesToDeleteListPath))
        # Import the CSV file containing safes to delete
        $safesToDeleteList = Import-Csv $safesToDeleteListPath -Delimiter ";"    
        Write-Host "`nCSV file imported successfully.`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any safes
        if ($safesToDeleteList.Count -eq 0) {        
            Write-Host "No safes found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No safes found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each safe in the list
        foreach ($safe in $safesToDeleteList) {

            try {
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Get the details of the safe to be deleted
                $safe_details = $this.getSafeDetails($safe, $auth_token)
                # Construct the URL for the API endpoint to delete the safe
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Safes/$($safe_details.safeUrlId)/"

                try {
                    # Send a DELETE request to delete the safe
                    $response = Invoke-WebRequest $url -Method 'DELETE' -Headers $headers
                    # If the request is successful (HTTP 204 No Content)
                    if( $response.StatusCode -eq 204) {
                        Write-Host "Deleting safe <$($safe.safeName)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Deleting safe <$($safe.safeName)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Deleting safe <$($safe.safeName)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Deleting safe <$($safe.safeName)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while deleting safe <$($safe.safeName)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while deleting safe <$($safe.safeName)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred while deleting safe <$($safe.safeName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while deleting safe <$($safe.safeName)> : $_.`n==========================================================")
            }
        }
        # Display success message after processing all safes
        Write-Host "`nDeleting all safes from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Deleting all safes from CSV file completed successfully.`n==========================================================")
    }
}