
# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
##############################################################################################################

# Import the class from the other file #######################################################################
. ./account_handler.ps1

# Define a class to handle CyberArk Central Policy Manager (CPM) actions
class CPMActionHandler {

    # Declare a string variable to store the PVWA URL
    [string] $pvwa_url
    # Declare an instance of AccountHandler to manage account-related operations
    [AccountHandler] $account_handler

    # Constructor to initialize the class (not used in this script but present for flexibility)
    CPMActionHandler() {}

    # Constructor to initialize the class with the PVWA URL
    CPMActionHandler([string] $pvwa_url){
        $this.pvwa_url = $pvwa_url
        # Initialize the AccountHandler with the PVWA URL
        $this.account_handler = [AccountHandler]::new($pvwa_url)
    }
    
###################################### Verify Credentials ######################################################  

# Method to verify credentials for accounts listed in a CSV file
    [void] VerifyCredentials([string] $auth_token){
        
        # Prompt the user for the path to the CSV file containing account details
        $accountListPath=""
        do {
            $accountListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $accountListPath)) {            
                Write-Host "CSV File path <$accountListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$accountListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $accountListPath))
        # Import the CSV file containing account details
        $accountList = Import-Csv $accountListPath -Delimiter ";"    
        Write-Host "`nCSV file imported successfully.`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any accounts
        if ($accountList.Count -eq 0) {        
            Write-Host "No accounts found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No accounts found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each account in the CSV file
        foreach ($account in $accountList) {
            # Define the headers for the request, including the authorization token
            $headers = @{
                "Authorization" = $auth_token
                "Content-Type"  = "application/json"
            }
            # Get the account details using the getAccountDetails method from the AccountHandler class (to retrieve the account ID)
            $account_details = $this.account_handler.getAccountDetails($account, $auth_token)
            # Construct the URL for the API endpoint to verify credentials
            $url = "https://$($this.pvwa_url)/PasswordVault/API/Accounts/$($account_details.id)/Verify/"

            try {
                # Send a POST request to the API endpoint to verify credentials
                $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers
                # If the request is successful (HTTP 200 OK)
                if( $response.StatusCode -eq 200) { 
                    Write-Host "Account <$($account.userName)> is scheduled for a password verify ...[OK]" -ForegroundColor Green
                    [LogHandler]::Instance.LogWrite("Account <$($account.userName)> is scheduled for a password verify successfully.`n==========================================================")
                } else {
                    # If the request fails, display an error message with the status code
                    Write-Host "Account <$($account.userName)> is scheduled for a password verify ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("Account <$($account.userName)> is scheduled for a password verify failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred when Verifing Credentials for account <$($account.userName)>  $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred when Verifing Credentials for account <$($account.userName)>  $_.`n==========================================================")
            }

        }
        # Display a success message after processing all accounts
        Write-Host "`nAll accounts is scheduled for a password verify from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("All accounts is scheduled for a password verify from CSV file completed successfully.`n==========================================================")
    }

###################################### Change Credentials Immediately ############################################  

# Method to change credentials immediately for accounts listed in a CSV file
    [void] ChangeCredentialsImmediately([string] $auth_token){
        # Prompt the user for the path to the CSV file containing account details
        $accountListPath=""
        do {
            $accountListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $accountListPath)) {            
                Write-Host "CSV File path <$accountListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$accountListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $accountListPath))
        # Import the CSV file containing account details
        $accountList = Import-Csv $accountListPath -Delimiter ";"    
        Write-Host "`nCSV file imported successfully.`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any accounts
        if ($accountList.Count -eq 0) {        
            Write-Host "No accounts found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No accounts found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each account in the CSV file   
        foreach ($account in $accountList) {
            # Define the headers for the request, including the authorization token
            $headers = @{
                "Authorization" = $auth_token
                "Content-Type"  = "application/json"
            }
            # Construct the body of the request with the ChangeEntireGroup parameter
            $body_change = @{
                #Do you want to apply the credential change to all accounts in the same group?
                "ChangeEntireGroup" = $($account.ChangeEntireGroup) # This should be a boolean value
            }   
            # Convert the body to JSON format with a depth of 10
            $body = $body_change | ConvertTo-Json -Depth 10
            # Get the account details using the getAccountDetails method from the AccountHandler class (to retrieve the account ID)
            $account_details = $this.account_handler.getAccountDetails($account, $auth_token)
            # Construct the URL for the API endpoint to change credentials immediately
            $url = "https://$($this.pvwa_url)/PasswordVault/API/Accounts/$($account_details.id)/Change/"
            # Convert the ChangeEntireGroup value to lowercase for comparison
            $val = $($account.ChangeEntireGroup).ToLower()

            try {
                # Send a POST request to the API endpoint to change credentials immediately
                $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                # If the request is successful (HTTP 200 OK)
                if( $response.StatusCode -eq 200) {
                    # Display a success message based on the ChangeEntireGroup value
                    if ($val -eq "true"){
                        Write-Host "Account <$($account.userName)> is scheduled for a password change immediately for entire group ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Account <$($account.userName)> is scheduled for a password change immediately for entire group successfully.`n==========================================================")
                    }elseif($val -eq "false"){ 
                        Write-Host "Account <$($account.userName)> is scheduled for a password change immediately (just for this account not for entire group) ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Account <$($account.userName)> is scheduled for a password change immediately (just for this account not for entire group) successfully.`n==========================================================")
                    }
                } else {
                    # If the request fails, display and log the error with the status code
                    if ($val -eq "true"){
                        Write-Host "Account <$($account.userName)> is scheduled for a password change immediately (just for this account not for entire group) ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Account <$($account.userName)> is scheduled for a password change immediately (just for this account not for entire group) failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }elseif($val -eq "false"){ 
                        Write-Host "Account <$($account.userName)> is scheduled for a password change immediately (just for this account not for entire group) ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Account <$($account.userName)> is scheduled for a password change immediately (just for this account not for entire group) failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred when Changing Credentials Immediately for account <$($account.userName)>  $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred when Changing Credentials Immediately for account <$($account.userName)>  $_.`n==========================================================")
            }

        }
        # Display a success message after processing all accounts
        Write-Host "`nAll accounts is scheduled for a password change immediately from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("All accounts is scheduled for a password change immediately from CSV file completed successfully.`n==========================================================")
    }

###################################### Change Credentials with the predefined Password ##############################

# Method to change credentials with a predefined password for accounts listed in a CSV file
    [void] ChangeCredentialsSetNextPassword([string] $auth_token){
        # Prompt the user for the path to the CSV file containing account details
        $accountListPath=""
        do {
            $accountListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $accountListPath)) {            
                Write-Host "CSV File path <$accountListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$accountListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $accountListPath))
        # Import the CSV file containing account details
        $accountList = Import-Csv $accountListPath -Delimiter ";"    
        Write-Host "`nCSV file imported successfully.`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any accounts
        if ($accountList.Count -eq 0) {        
            Write-Host "No accounts found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No accounts found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each account in the CSV file
        foreach ($account in $accountList) {
            # Define the headers for the request, including the authorization token
            $headers = @{
                "Authorization" = $auth_token
                "Content-Type"  = "application/json"
            }
            # Construct the body of the request with the ChangeImmediately and NewCredentials parameters
            $body_change = @{                
                "ChangeImmediately" = $($account.ChangeImmediately) # This should be a boolean value
                "NewCredentials" = $($account.NewCredentials)
            }   
            # Convert the body to JSON format with a depth of 10
            $body = $body_change | ConvertTo-Json -Depth 10
            # Get the account details using the getAccountDetails method from the AccountHandler class (to retrieve the account ID)
            $account_details = $this.account_handler.getAccountDetails($account, $auth_token)
            # Construct the URL for the API endpoint to change credentials with the predefined password
            $url = "https://$($this.pvwa_url)/PasswordVault/API/Accounts/$($account_details.id)/SetNextPassword/"
            # Convert the ChangeImmediately value to lowercase for comparison
            $val = $($account.ChangeImmediately).ToLower()

            try {
                # Send a POST request to the API endpoint to change credentials with the predefined password
                $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                # If the request is successful (HTTP 200 OK)
                if( $response.StatusCode -eq 200 ) {
                    # Display a success message based on the ChangeImmediately value
                    if ($val -eq "true"){
                        Write-Host "Account <$($account.userName)> is scheduled for a password change immediately with the predefined password ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Account <$($account.userName)> is scheduled for a password change immediately with the predefined password successfully.`n==========================================================")
                    }elseif($val -eq "false"){ 
                        Write-Host "Account <$($account.userName)> is scheduled for a password change not immediately with the predefined password ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Account <$($account.userName)> is scheduled for a password change not immediately with the predefined password successfully.`n==========================================================")
                    }
                } else {
                    # If the request fails, display and log the error with the status code
                    if ($val -eq "true"){
                        Write-Host "Account <$($account.userName)> is scheduled for a password change immediately with the predefined password ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Account <$($account.userName)> is scheduled for a password change immediately with the predefined password failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }elseif($val -eq "false"){ 
                        Write-Host "Account <$($account.userName)> is scheduled for a password change not immediately with the predefined password ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Account <$($account.userName)> is scheduled for a password change not immediately with the predefined password failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred when Changing Credentials with the predefined password for account <$($account.userName)>  $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred when Changing Credentials with the predefined password for account <$($account.userName)>  $_.`n==========================================================")
            }

        }
        # Display a success message after processing all accounts
        Write-Host "`nAll accounts is scheduled for a password change immediately with the predefined password from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("All accounts is scheduled for a password change immediately with the predefined password from CSV file completed successfully.`n==========================================================")
    }

###################################### Change Credentials In The Vault ################################################ 

# Method to change credentials in the vault for accounts listed in a CSV file
    [void] ChangeCredentialsInTheVault([string] $auth_token){
        # Prompt the user for the path to the CSV file containing account details
        $accountListPath=""
        do {
            $accountListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $accountListPath)) {            
                Write-Host "CSV File path <$accountListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$accountListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $accountListPath))
        # Import the CSV file containing account details
        $accountList = Import-Csv $accountListPath -Delimiter ";"    
        Write-Host "`nCSV file imported successfully.`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any accounts
        if ($accountList.Count -eq 0) {        
            Write-Host "No accounts found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No accounts found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each account in the CSV file 
        foreach ($account in $accountList) {
            # Define the headers for the request, including the authorization token
            $headers = @{
                "Authorization" = $auth_token
                "Content-Type"  = "application/json"
            }
            # Construct the body of the request with the NewCredentials parameter
            $body_change = @{
                #Do you want to apply the credential change to all accounts in the same group?
                "NewCredentials" = $($account.NewCredentials)
            }   
            # Convert the body to JSON format with a depth of 10
            $body = $body_change | ConvertTo-Json -Depth 10
            # Get the account details using the getAccountDetails method from the AccountHandler class (to retrieve the account ID)
            $account_details = $this.account_handler.getAccountDetails($account, $auth_token)
            # Construct the URL for the API endpoint to change credentials in the vault
            $url = "https://$($this.pvwa_url)/PasswordVault/API/Accounts/$($account_details.id)/Password/Update/"

            try {
                # Send a POST request to the API endpoint to change credentials in the vault
                $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                # If the request is successful (HTTP 200 OK)
                if( $response.StatusCode -eq 200) {                    
                    Write-Host "Account <$($account.userName)> is scheduled for a password change in the vault ...[OK]" -ForegroundColor Green
                    [LogHandler]::Instance.LogWrite("Account <$($account.userName)> is scheduled for a password change in the vault successfully.`n==========================================================")
                } else {
                    # If the request fails, display and log the error with the status code
                    Write-Host "Account <$($account.userName)> is scheduled for a password change in the vault ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("Account <$($account.userName)> is scheduled for a password change in the vault failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred when Changing Credentials in the vault for account <$($account.userName)>  $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred when Changing Credentials in the vault for account <$($account.userName)>  $_.`n==========================================================")
            }

        }
        # Display a success message after processing all accounts
        Write-Host "`nAll accounts is scheduled for a password change in the vault from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("All accounts is scheduled for a password change in the vault from CSV file completed successfully.`n==========================================================")
    }

###################################### Reconcile Credentials ######################################################### 

# Method to reconcile credentials for accounts listed in a CSV file
    [void] ReconcileCredentials([string] $auth_token){
        # Prompt the user for the path to the CSV file containing account details
        $accountListPath=""
        do {
            $accountListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $accountListPath)) {            
                Write-Host "CSV File path <$accountListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$accountListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $accountListPath))
        # Import the CSV file containing account details
        $accountList = Import-Csv $accountListPath -Delimiter ";"    
        Write-Host "`nCSV file imported successfully.`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any accounts
        if ($accountList.Count -eq 0) {        
            Write-Host "No accounts found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No accounts found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each account in the CSV file
        foreach ($account in $accountList) {
            # Define the headers for the request, including the authorization token
            $headers = @{
                "Authorization" = $auth_token
                "Content-Type"  = "application/json"
            }
            # Get the account details using the getAccountDetails method from the AccountHandler class (to retrieve the account ID)
            $account_details = $this.account_handler.getAccountDetails($account, $auth_token)
            # Construct the URL for the API endpoint to reconcile credentials
            $url = "https://$($this.pvwa_url)/PasswordVault/API/Accounts/$($account_details.id)/Reconcile/"

            try {
                # Send a POST request to the API endpoint to reconcile credentials
                $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers
                # If the request is successful (HTTP 200 OK)
                if( $response.StatusCode -eq 200) {
                    Write-Host "Account <$($account.userName)> is scheduled for a password reconcile ...[OK]" -ForegroundColor Green
                    [LogHandler]::Instance.LogWrite("Account <$($account.userName)> is scheduled for a password reconcile successfully.`n==========================================================")
                } else {
                    # If the request fails, display and log the error with the status code
                    Write-Host "Account <$($account.userName)> is scheduled for a password reconcile ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("Account <$($account.userName)> is scheduled for a password reconcile failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred when Reconciling Credentials for account <$($account.userName)>  $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred when Reconciling Credentials for account <$($account.userName)>  $_.`n==========================================================")
            }

        }
        # Display a success message after processing all accounts
        Write-Host "`nAll accounts is scheduled for a password reconcile from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("All accounts is scheduled for a password reconcile from CSV file completed successfully.`n==========================================================")
    }
}