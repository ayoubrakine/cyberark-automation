# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
##############################################################################################################

# Define a class to handle system health components
class SystemHealthHandler {

    # Declare a string variable to store the PVWA URL
    [string] $pvwa_url

    # Constructor to initialize the class (not used in this script but present for flexibility)
    SystemHealthHandler() {}

    # Constructor to initialize the class with the PVWA URL
    SystemHealthHandler([string] $pvwa_url){
        $this.pvwa_url = $pvwa_url
    }

###################################### Get Components Monitoring Summary ####################################

# Method to retrieve the components monitoring summary
    [PSCustomObject] getComponentsMonitoringSummary([string] $auth_token) {

        # Define the headers for the request, including the authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Construct the URL for the API endpoint to get components monitoring summary
        $url = "https://$($this.pvwa_url)/PasswordVault/API/ComponentsMonitoringSummary/"
        
        try {
            # Send a GET request to retrieve the components monitoring summary
            $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers 
            # Parse the response content
            $jsonContent = $response.Content | ConvertFrom-Json
            # Convert the full content back to JSON, depth 10 to include all fields
            $jsonOutput = $jsonContent | ConvertTo-Json -Depth 10
            Write-Host "Components Monitoring Summary retrieved successfully" -ForegroundColor Green
            [LogHandler]::Instance.LogWrite("Components Monitoring Summary retrieved successfully.`n==========================================================")
            # Return the JSON string containing the components monitoring summary
            return $jsonOutput 
        
        } catch {
            # Catch any exceptions during the request and log them
            Write-Host "An error occurred when retreiving Components Monitoring Summary : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred when retreiving Components Monitoring Summary : $_.`n==========================================================")
            return $null
        }
}

###################################### Get Components Monitoring Details ####################################

# Method to retrieve the components monitoring details from a CSV file
    [void] getComponentsMonitoringDetails([string] $auth_token) { 

        # Prompt the user to enter the full path to the CSV file containing component IDs
        $componentListPath=""
        do {
            $componentListPath = Read-Host "Please enter full path to your CSV file "

            if (-not (Test-Path $componentListPath)) {                
                Write-Host "File path <$componentListPath> does not exist. Please try again" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$componentListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $componentListPath))
        # Import the CSV file containing component IDs
        $componentList = Import-Csv $componentListPath -Delimiter ";"        
        Write-Host "CSV file imported successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the component list is empty
        if ($componentList.Count -eq 0) {
            [LogHandler]::Instance.ErrorWrite("No components found in the CSV file. Please fill in the file and try again.`n==========================================================")
            Write-Host "No components found in the CSV file." -ForegroundColor Yellow
        }
        # Define the headers for the request, including the authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }

        try {
            # Iterate through each component in the list
            foreach ($component in $componentList) {
                # Construct the URL for the API endpoint to get details for each component
                $url = "https://$($this.pvwa_url)/PasswordVault/API/ComponentsMonitoringDetails/$($component.componentId)/"

                try {
                    # Send a GET request to retrieve the details for each component
                    $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers
                    # If the request is successful (HTTP 200 OK)
                    if ($response.StatusCode -eq 200) {
                        Write-Host "`n================  Details for component <$($component.componentId)>  ================" -ForegroundColor Green    
                        # Parse the JSON response content                    
                        $jsonContent = $response.Content | ConvertFrom-Json

                        # Convert the full content (including Users) back to JSON, depth 10 to include all fields
                        $jsonOutput = $jsonContent | ConvertTo-Json -Depth 10

                        Write-Host $jsonOutput -ForegroundColor Yellow
                        [LogHandler]::Instance.LogWrite("Retrieved all details for component <$($component.componentId)> completed successfully.`n==========================================================")
                        
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Retrieving details for component : <$($component.componentId)> failed. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Retrieving details for component : <$($component.componentId)> failed. Returned Status code : $($response.StatusCode).")
                    }

                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "Error when calling Component API for component <$($component.componentId)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("Error when calling Component API for component <$($component.componentId)> : $_.")
                }
            }
            # If all components were processed successfully, display a success message
            Write-Host "Retrieving details for all components from CSV file completed successfully" -ForegroundColor Green
            [LogHandler]::Instance.LogWrite("Retrieving details for all components from CSV file completed successfully.`n==========================================================")
        } catch {
            # Catch any exceptions during the request and log them
            Write-Host "An error occurred : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred : $_.`n==========================================================")
        }
    }
}