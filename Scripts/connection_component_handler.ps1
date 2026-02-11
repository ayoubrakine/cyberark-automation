# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
##############################################################################################################

# Define a class to handle connection components
class ConnectionComponentHandler {

    # Declare a string variable to store the PVWA URL
    [string] $pvwa_url

    # Constructor to initialize the class (not used in this script but present for flexibility)
    ConnectionComponentHandler() {}

     # Constructor to initialize the class with the PVWA URL
    ConnectionComponentHandler([string] $pvwa_url){
        $this.pvwa_url = $pvwa_url
    }
    
###################################### Get All Connection Components ##########################################

# Method to retrieve all connection components 
    [PSCustomObject] getAllConnectionComponents([string] $auth_token){
        # Define the headers for the request, including the authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Construct the URL for the API endpoint to get connection components
        $url = "https://$($this.pvwa_url)/PasswordVault/API/PSM/Connectors/"
        
        try {
            # Send a GET request to retrieve all connection components
            $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers
            # If the request is successful (HTTP 200 OK)
            if ($response.StatusCode -eq 200) {
                # Parse the JSON response content
                $parsedResponse = $response.Content | ConvertFrom-Json
                # Total number of platforms listed
                $total_connectionComponents = $parsedResponse.Total

                Write-Host "Retrieved <$total_connectionComponents> connection components successfully" -ForegroundColor Green
                [LogHandler]::Instance.LogWrite("Retrieved <$total_connectionComponents> connection components successfully.`n==========================================================")
                # Convert the parsed response to JSON format with a depth of 10
                $all_connectionComponents = $($parsedResponse | ConvertTo-Json -Depth 10)
                # Return the JSON string containing all connection components
                return $all_connectionComponents
            } else {
                # If the request fails, display and log the error with the status code
                Write-Host "Retrieving connection components failed. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("Retrieving connection components failed. Returned Status code : $($response.StatusCode).")
            }
        } catch {
            # Catch any exceptions during the request and log them
            Write-Host "An error occurred while retrieving connection components : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving connection components : $_.`n==========================================================")           
        }
    # If the request fails or an error occurs, return an empty array
    return @()
}

###################################### Import Connection Components ###########################################

# Method to import connection components from a CSV file
    [void] importConnectionComponents([string] $auth_token){
        
        # Prompt the user to enter the full path to the CSV file containing connection components zip file paths
        $connectioncomponentsToImportListPath = Read-Host "Please Enter full path to your CSV file which contains connection components zip file paths "
        if (-Not (Test-Path $connectioncomponentsToImportListPath)) {
                Write-Host "CSV file at path: <$connectioncomponentsToImportListPath> does not exist. Please try again." -ForegroundColor Red                
                [LogHandler]::Instance.ErrorWrite("CSV File path <$connectioncomponentsToImportListPath> does not exist. Please try again.`n==========================================================")
                continue
        }
        # Import the CSV file containing connection components zip file paths
        $connectioncomponentsToImportList = import-CSV $connectioncomponentsToImportListPath -Delimiter ";"
        Write-Host "CSV file imported successfully." -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any connection components
        if ($connectioncomponentsToImportList.Count -eq 0) {        
            Write-Host "No connection components found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No connection components found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each connection component in the list
        foreach ($connectioncomponent in $connectioncomponentsToImportList) {

            # Resolves the path of the ZIP file specified in the 'pathToZipFile' property of the 'connectioncomponent' object and stores it in the '$zipPath' variable.
            $zipPath = Resolve-Path -Path $connectioncomponent.pathToZipFile
            
            # Read the content of the ZIP file into a byte array
            $zipBytes = [System.IO.File]::ReadAllBytes($zipPath)

            # Encode the content in Base64
            $encodedZip = [System.Convert]::ToBase64String($zipBytes)

            # Define the headers for the request, including the authorization token
            $headers = @{
                "Authorization" = $auth_token
                "Content-Type"  = "application/json"
            }
            # Construct the URL for the API endpoint to import connection components
            $url = "https://$($this.pvwa_url)/PasswordVault/API/ConnectionComponents/Import/"

            # Prepare the body of the request with the encoded ZIP file
            $body = @{
                "ImportFile" = $encodedZip
            } | ConvertTo-Json -Depth 2

            # Initialize a variable to store the exception message
            $exceptionmsg = ""

            try {
                # Send a POST request to import the connection component
                $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                # Parse the JSON response content (convert the response content from JSON to a PowerShell object)
                $rep = ConvertFrom-Json $response.Content
                # Store the connection component ID in the exception message for logging
                $exceptionmsg = $($rep.ConnectionComponentID)
                # If the request is successful (HTTP 201 Created)
                if( $response.StatusCode -eq 201) {
                    Write-Host "Importing Connection Component <$($rep.ConnectionComponentID)> ...[OK]" -ForegroundColor Green
                    [LogHandler]::Instance.LogWrite("Importing Connection Component <$($rep.ConnectionComponentID)> completed successfully.`n==========================================================")
                } else {
                    # If the request fails, display and log the error with the status code
                    Write-Host "Importing Connection Component <$($rep.ConnectionComponentID)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("Importing Connection Component <$($rep.ConnectionComponentID)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                }
            } catch {    
                # Catch any exceptions during the request and log them            
                Write-Host "An error occurred while importing this connection component : $exceptionmsg : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while importing this connection component : $exceptionmsg : $_.`n==========================================================")
            }
        }
    # Display success message after processing all connection components
    Write-Host "Importing all connection components from CSV file completed successfully" -ForegroundColor Green        
    [LogHandler]::Instance.LogWrite("Importing all connection components from CSV file completed successfully.`n==========================================================")
    }
}