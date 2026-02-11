# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
##############################################################################################################

# Define a class for managing CyberArk account operations
class AccountHandler {

    # Declare a string variable to store the PVWA URL
    [string] $pvwa_url

    # Constructor to initialize the class (not used in this script but present for flexibility)
    AccountHandler() {}

    # Constructor to initialize the class with the PVWA URL
    AccountHandler([string] $pvwa_url) {
        $this.pvwa_url = $pvwa_url
    }

###################################### Get All Accounts ######################################################

# Method to retrieve all accounts from CyberArk using the provided authentication token
    [PSCustomObject] getAllAccounts([string] $auth_token){
        # Set HTTP headers with authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Construct the API URL to get all accounts
        $url = "https://$($this.pvwa_url)/PasswordVault/API/Accounts"
        
        try {
            # Send a GET request to retrieve all accounts
            $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers
            # If retrieving all accounts is successful (HTTP 200 OK)
            if ($response.StatusCode -eq 200){
                $response = ConvertFrom-Json $response
                if ($response.value.Count -gt 0) {
                    # Log the successful operation
                    [LogHandler]::Instance.LogWrite("Retrieved all accounts successfully.`n==========================================================")
                    # Return the list of accounts 
                    return $response.value
                }
                else {
                    # If no accounts are found, log and display a message
                    [LogHandler]::Instance.ErrorWrite("No account was found.`n==========================================================")
                    return [PSCustomObject]@{}  # Empty object if no accounts are found
                }
            } else {         
                # If retrieving all accounts failed, display and log the error with the status code   
                [LogHandler]::Instance.ErrorWrite("Retrieving all accounts failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                return "Retrieving all accounts failed. Returned Status code : $($response.StatusCode)"
            }
        } catch {
            # Log and display error if the request fails
            [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving all accounts : $_.`n==========================================================")
            return "An error occurred while retrieving all accounts : $_"
        }
    }

###################################### Get Accounts Details ######################################################
 
# Method to retrieve details of a specific account from CyberArk using the provided authentication token  
    [PSCustomObject] getAccountDetails([PSCustomObject] $account,[string] $auth_token) {
        
        # Set HTTP headers with authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Construct the API URL to get account details based on the account's username and safe name
        $url = "https://$($this.pvwa_url)/PasswordVault/API/Accounts/?search=$($account.userName)&filter=safename eq $($account.safeName)"
        
        try {
            # Send a GET request to retrieve account details
            $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers
            # If retrieving account details is successful (HTTP 200 OK)
            if ($response.StatusCode -eq 200) {
                $response = ConvertFrom-Json $response
                foreach ($result_account in $response.value) {
                    if ($result_account.userName -eq $account.userName) {
                        [LogHandler]::Instance.LogWrite("Retrieved all details for account : <$($result_account.userName)> completed successfully.`n==========================================================")
                        return $result_account
                    }
                }
                # Account not found
                Write-Host "Account <$($account.userName)> not found in the safe : <$($account.safeName)>" -ForegroundColor Yellow
                [LogHandler]::Instance.ErrorWrite("Account <$($account.userName)> not found in the safe : <$($account.safeName)>.")
                # Return an empty object if the account is not found
                return [PSCustomObject]@{}
            }
            else {
                # If retrieving account details failed, display and log the error with the status code
                Write-Host "Retrieving details for account <$($account.userName)> failed. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("Retrieving details for account <$($account.userName)> failed. Returned Status code : $($response.StatusCode).")
                # Return an empty object if an error occurs
                return [PSCustomObject]@{}
            }
        }
        catch {
            # Log and display error if the request fails
            Write-Host "An error occurred when retrieving details for <$($account.userName)> : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred when retrieving details for <$($account.userName)> : $_.`n==========================================================")
            # Return an empty object if an error occurs
            return [PSCustomObject]@{}
        }
    }

###################################### Add Accounts ######################################################

# Method to add account details of a specific account using the provided authentication token.  
    [void] addAccounts ([string] $auth_token) {

        # Prompt user for the path to the CSV file containing account details
        $accountsToAddListPath=""
        do {
            $accountsToAddListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $accountsToAddListPath)) {                
                Write-Host "File path <$accountsToAddListPath> does not exist. Please try again" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$accountsToAddListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $accountsToAddListPath))
        # Import the CSV file containing account details
        $accountsToAddList = Import-Csv $accountsToAddListPath -Delimiter ";"        
        Write-Host "CSV file imported successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any accounts
        if ($accountsToAddList.Count -eq 0) {
            Write-Host "No accounts found in the CSV file." -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No accounts found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each account in the CSV file
        foreach ($account in $accountsToAddList) {
            try {
                # Prepare the account data to be added (convert the account details into a hashtable format)
                $account_data = @{
                    "name" = $account.name
                    "address" = $account.address
                    "userName" = $account.userName
                    "platformId" = $account.platformId
                    "safeName" = $account.safeName
                    "secretType" = $account.secretType
                    "secret" = $account.secret
                    "platformAccountProperties" = @{}
                    "secretManagement" = @{
                        "automaticManagementEnabled" = $account.automaticManagementEnabled
                        "manualManagementReason" = $account.manualManagementReason
                    }
                    "remoteMachinesAccess" = @{
                        "remoteMachines" = $account.remoteMachines
                        "accessRestrictedToRemoteMachines" = $account.accessRestrictedToRemoteMachines
                    }
                    
                }
                # Set HTTP headers with authorization token and content type
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Convert the account data to JSON format
                $body = $account_data | ConvertTo-Json -Depth 10
                # Construct the API URL to add the account
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Accounts/"
                
            try {
                # Send a POST request to add the account
                $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                if ($response.StatusCode -eq 201) {  
                    # If adding account is successful (HTTP 201 Created)                  
                    Write-Host "Adding account <$($account_data['userName'])> ...[OK]" -ForegroundColor Green
                    [LogHandler]::Instance.LogWrite("Adding account <$($account_data['userName'])> completed successfully.`n==========================================================")
                } else {   
                    # If adding account failed, display and log the error with the status code                 
                    Write-host "Adding account <$($account_data['userName'])> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("Adding account <$($account_data['userName'])> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                }
            } catch {   
                # Catch any exceptions during the account addition process and log them             
                Write-Host "An error occurred while adding account <$($account['userName'])> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while adding account <$($account['userName'])> : $_.`n==========================================================")
            }
            
        } catch {          
            # Log and display error if the request fails  
            Write-Host "An error occurred while adding account <$($account['userName'])> : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while adding account <$($account['userName'])> : $_.")
        }
    }
    # Display success message after processing all accounts
    Write-Host "Adding all accounts from CSV file completed successfully" -ForegroundColor Green
    [LogHandler]::Instance.LogWrite("Adding all accounts from CSV file completed successfully.`n==========================================================")
    }

###################################### Update Accounts ######################################################

# Method to update account details of a specific account using the provided authentication token
    [void] updateAccounts([string] $auth_token){
        # Set HTTP headers with authorization token
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        # Prompt user for the path to the CSV file containing account details 
        $accountsToUpdateListPath=""
        do {
            $accountsToUpdateListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $accountsToUpdateListPath)) {                
                Write-Host "CSV File path <$accountsToUpdateListPath> does not exist. Please try again" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$accountsToUpdateListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $accountsToUpdateListPath))
        # Import the CSV file containing accounts to update
        $accountsToUpdateList = Import-Csv $accountsToUpdateListPath -Delimiter ";"        
        Write-Host "CSV file imported successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any accounts
        if ($accountsToUpdateList.Count -eq 0) {
            [LogHandler]::Instance.ErrorWrite("No accounts found in the CSV file. Please fill in the file and try again.`n==========================================================")
            Write-Host "No accounts found in the CSV file." -ForegroundColor Yellow
        }
        # Iterate through each account in the CSV file
        foreach ($account in $accountsToUpdateList) {
            try {
                # Set HTTP headers with authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Retrieve the account details using the getAccountDetails method (to get the account ID)
                $account_details = $this.getAccountDetails($account, $auth_token)
                # Construct the API URL to update the account based on the account ID
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Accounts/$($account_details.id)"
                # Prepare the body contains the operation, path, and value to be updated
                $body = @(
                    @{
                        "op" = "$($account.op)" # The operation to be performed (e.g., "replace")
                        "path" = "/$($account.path)" # The property to be updated
                        "value" = "$($account.value)" # The new value to be set for that property
                    }
                )
                # Convert the body to JSON format
                $body = ConvertTo-Json $body -Depth 10

                try {
                    # Send a PATCH request to update the account
                    $response = Invoke-WebRequest $url -Method 'PATCH' -Headers $headers -Body $body
                    # If updating account is successful (HTTP 200 OK)
                    if ($response.StatusCode -eq 200) {                        
                        Write-Host "Updating account <$($account.name)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Updating account <$($account.name)> completed successfully.`n==========================================================")
                    } else {     
                        # If updating account failed, display and log the error with the status code                  
                        Write-Host "Updating account <$($account.name)> ...[Failed]. Returned Status code : $($response.StatusCode)"  -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Updating account <$($account.name)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {       
                    # Catch any exceptions during the account update process and log them             
                    Write-Host "An error occurred while updating account <$($account.name)> : $_"  -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while updating account <$($account.name)> : $_.`n==========================================================")
                }
        } catch {      
            # Log and display error if the request fails      
            Write-Host "An error occurred while processing account <$($account.name)> : $_"  -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while processing account <$($account.name)> : $_.`n==========================================================")
        }
    }
    # Display success message after processing all accounts
    Write-Host "Updating all accounts from CSV file completed successfully" -ForegroundColor Green
    [LogHandler]::Instance.LogWrite("Updating all accounts from CSV file completed successfully.`n==========================================================")
}
        
###################################### Delete Accounts ######################################################

# Method to delete accounts from CyberArk using the provided authentication token
    [void] deleteAccounts([string] $auth_token){        

        # Prompt user for the path to the CSV file containing accounts to delete
        $accountsToDeleteListPath=""
        do {
            $accountsToDeleteListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $accountsToDeleteListPath)) {            
                Write-Host "CSV File path <$accountsToDeleteListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$accountsToDeleteListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $accountsToDeleteListPath))
        # Import the CSV file containing accounts to delete
        $accountsToDelete = Import-Csv $accountsToDeleteListPath -Delimiter ";"    
        Write-Host "CSV file imported successfully." -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any accounts
        if ($accountsToDelete.Count -eq 0) {        
            Write-Host "No accounts found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No accounts found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each account in the CSV file
        foreach ($account in $accountsToDelete) {
            try {
                # Set HTTP headers with authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Retrieve the account details using the getAccountDetails method (to get the account ID)
                $account_details = $this.getAccountDetails($account, $auth_token)
                # Construct the API URL to delete the account based on the account ID
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Accounts/$($account_details.id)/"
                
                try {
                    # Send a DELETE request to remove the account
                    $response = Invoke-WebRequest $url -Method 'DELETE' -Headers $headers
                    # If deleting account is successful (HTTP 204 No Content)
                    if( $response.StatusCode -eq 204){                        
                        write-host "Deleting account <$($account.userName)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Deleting account <$($account.userName)> completed successfully.`n==========================================================")
                    }else{       
                        # If deleting account failed, display and log the error with the status code                 
                        write-host "Deleting account <$($account.userName)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Deleting account <$($account.userName)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {     
                    # Catch any exceptions during the account deletion process and log them               
                    write-host "An error occurred: $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred: $_.`n==========================================================")
                }
            } catch {                
                # Log and display error if the request fails
                write-host "An error occurred while deleting account <$($account.userName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while deleting account <$($account.userName)> : $_.`n==========================================================")
            }
        }
    # Display success message after processing all accounts
    Write-Host "`nDeleting all accounts from CSV file completed successfully" -ForegroundColor Green
    [LogHandler]::Instance.LogWrite("Deleting all accounts from CSV file completed successfully.`n==========================================================")
    }
}