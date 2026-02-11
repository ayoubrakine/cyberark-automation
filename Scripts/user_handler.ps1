# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
##############################################################################################################

# Define a class to handle user management 
class UserHandler {

    # Declare a string variable to store the PVWA URL
    [string] $pvwa_url

    # Constructor to initialize the class (not used in this script but present for flexibility)
    UserHandler() {}
    # Constructor to initialize the class with the PVWA URL
    UserHandler([string] $pvwa_url){
        $this.pvwa_url = $pvwa_url
    }

###################################### Get All Users ######################################################

# Method to retrieve all users from the PVWA
    [PSCustomObject] getAllUsers([string] $auth_token) {

        # Define the headers for the request, including the authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Construct the URL for the API endpoint to get all users
        $url = "https://$($this.pvwa_url)/PasswordVault/API/Users/"
        
        try {
            # Send a GET request to retrieve all users
            $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers
            # Parse the JSON response content
            $jsonContent = $response.Content | ConvertFrom-Json 
            # Get the total number of users from the response
            $total_users = $jsonContent.Total
            Write-Host "Retrieved $total_users users successfully" -ForegroundColor Green
            [LogHandler]::Instance.LogWrite("Retrieved $total_users users successfully.`n==========================================================")

            # Convert the full content (including Users) back to JSON, depth 10 to include all fields
            $jsonOutput = $jsonContent | ConvertTo-Json -Depth 10
            # Return the JSON string containing all users
            return $jsonOutput
        
        } catch {
            # If the request fails, display and log the error 
            Write-Host "An error occurred while retrieving all users : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving all users : $_.`n==========================================================")
            return $null
        }
    }

###################################### Get Users Details ######################################################

# Method to retrieve details for a specific user
    [PSCustomObject] getUserDetails([PSCustomObject] $user,[string] $auth_token) {

        # Define the headers for the request, including the authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Construct the URL for the API endpoint to get user details
        $url = "https://$($this.pvwa_url)/PasswordVault/API/Users?search=$($user.username)&ExtendedDetails=true"
        
        try {
            # Send a GET request to retrieve user details
            $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers
            # If the request is successful (HTTP 200 OK)
            if ($response.StatusCode -eq 200) {
                # Parse the JSON response content
                $response = ConvertFrom-Json $response
                # Iterate through the users in the response
                foreach ($result_user in $response.Users) { 
                    # Check if the user exists in the response
                    if ($result_user.username -eq $user.username) {                        
                        return $result_user
                    }
                }
                # Account not found
                Write-Host "User <$($user.username)> not found." -ForegroundColor Yellow
                [LogHandler]::Instance.LogWrite("User <$($user.username)> not found.`n==========================================================")
                return [PSCustomObject]@{}
            }
            else {
                # If the request fails, display and log the error with the status code
                Write-Host "Retrieving details for user <$($user.username)> failed. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("Retrieving details for user <$($user.username)> failed. Returned Status code : $($response.StatusCode).")
                return [PSCustomObject]@{}
            }
        }
        catch {
            # Catch any exceptions during the request and log them
            Write-Host "An error occurred while retrieving details for user <$($user.username)> : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving details for user <$($user.username)> : $_.`n==========================================================")
            return [PSCustomObject]@{}
        }
    }

###################################### Activate Users ######################################################

# Method to activate users
    [void] activateUsers([string] $auth_token){

        # Prompt the user for the path to the CSV file containing users to activate
        $usersToActivateListPath=""
        do {
            $usersToActivateListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $usersToActivateListPath)) {                
                Write-Host "File path <$usersToActivateListPath> does not exist. Please try again" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$usersToActivateListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $usersToActivateListPath))
        # Import the CSV file containing users to activate
        $usersToActivateList = Import-Csv $usersToActivateListPath -Delimiter ";"        
        Write-Host "CSV file imported successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any users
        if ($usersToActivateList.Count -eq 0) {
            [LogHandler]::Instance.ErrorWrite("No users found in the CSV file. Please fill in the file and try again.`n==========================================================")
            Write-Host "No users found in the CSV file." -ForegroundColor Yellow
        }
        # Iterate through each user in the list
        foreach ($user in $usersToActivateList) {
            try {
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }                
                # Retrieve user details using the getUserDetails method (to get the user ID)
                $user_details = $this.getUserDetails($user, $auth_token)
                # Construct the URL for the API endpoint to activate the user
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Users/$($user_details.id)/Activate/"

                try {
                    # Send a POST request to activate the user
                    $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers
                    # If the request is successful (HTTP 200 OK)
                    if( $response.StatusCode -eq 200) {
                        Write-Host "Activating user <$($user.username)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Activating user <$($user.username)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Activating user <$($user.username)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Activating user <$($user.username)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while activating user <$($user.username)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while activating user <$($user.username)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred while activating user <$($user.username)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while activating user <$($user.username)> : $_.`n==========================================================")
            }
        }
        # Display a success message after activating all users
        Write-Host "Activating all users from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Activating all users from CSV file completed successfully.`n==========================================================")
    }

###################################### Enable Users ######################################################

# Method to enable users
    [void] enableUsers([string] $auth_token){

        # Prompt the user for the path to the CSV file containing users to enable
        $usersToEnableListPath=""
        do {
            $usersToEnableListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $usersToEnableListPath)) {                
                Write-Host "File path <$usersToEnableListPath> does not exist. Please try again" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$usersToEnableListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $usersToEnableListPath))
        # Import the CSV file containing users to enable
        $usersToEnableList = Import-Csv $usersToEnableListPath -Delimiter ";"        
        Write-Host "CSV file imported successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any users
        if ($usersToEnableList.Count -eq 0) {
            [LogHandler]::Instance.ErrorWrite("No users found in the CSV file. Please fill in the file and try again.`n==========================================================")
            Write-Host "No users found in the CSV file." -ForegroundColor Yellow
        }
        # Iterate through each user in the list
        foreach ($user in $usersToEnableList) {
            try {
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }                
                # Retrieve user details using the getUserDetails method (to get the user ID)
                $user_details = $this.getUserDetails($user, $auth_token)
                # Construct the URL for the API endpoint to enable the user
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Users/$($user_details.id)/enable/"

                try {
                    # Send a POST request to enable the user
                    $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers
                    # If the request is successful (HTTP 200 OK)
                    if( $response.StatusCode -eq 200) {
                        Write-Host "Enabling user <$($user.username)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Enabling user <$($user.username)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Enabling user <$($user.username)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Enabling user <$($user.username)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while enabling user <$($user.username)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while enabling user <$($user.username)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred while enabling user <$($user.username)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while enabling user <$($user.username)> : $_.`n==========================================================")
            }
        }
        # Display a success message after enabling all users
        Write-Host "Enabling all users from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Enabling all users from CSV file completed successfully.`n==========================================================")
    }

###################################### Disable Users ######################################################

# Method to disable users
    [void] disableUsers([string] $auth_token){
        # Prompt the user for the path to the CSV file containing users to disable
        $usersToDisableListPath=""
        do {
            $usersToDisableListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $usersToDisableListPath)) {                
                Write-Host "File path <$usersToDisableListPath> does not exist. Please try again" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$usersToDisableListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $usersToDisableListPath))
        # Import the CSV file containing users to disable
        $usersToDisableList = Import-Csv $usersToDisableListPath -Delimiter ";"        
        Write-Host "CSV file imported successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any users
        if ($usersToDisableList.Count -eq 0) {
            [LogHandler]::Instance.ErrorWrite("No users found in the CSV file. Please fill in the file and try again.`n==========================================================")
            Write-Host "No users found in the CSV file." -ForegroundColor Yellow
        }
        # Iterate through each user in the list
        foreach ($user in $usersToDisableList) {
            try {
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }                
                # Retrieve user details using the getUserDetails method (to get the user ID)
                $user_details = $this.getUserDetails($user, $auth_token)
                # Construct the URL for the API endpoint to disable the user
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Users/$($user_details.id)/disable/"

                try {
                    # Send a POST request to disable the user
                    $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers
                    # If the request is successful (HTTP 200 OK)
                    if( $response.StatusCode -eq 200) {
                        Write-Host "Disactivating user <$($user.username)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Disactivating user <$($user.username)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Disactivating user <$($user.username)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Disactivating user <$($user.username)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while disactivating user <$($user.username)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while disactivating user <$($user.username)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred while disactivating user <$($user.username)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while disactivating user <$($user.username)> : $_.`n==========================================================")
            }
        }
        # Display a success message after disactivating all users
        Write-Host "Disactivating all users from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Disactivating all users from CSV file completed successfully.`n==========================================================")
    }

###################################### Reset Password Users ###################################################  

# Method to reset passwords for users 
    [void] resetPasswordForUsers([string] $auth_token){

        # Prompt the user for the path to the CSV file containing users and their new passwords
        $usersToResetPassListPath=""
        do {
            $usersToResetPassListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $usersToResetPassListPath)) {                
                Write-Host "File path <$usersToResetPassListPath> does not exist. Please try again" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$usersToResetPassListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $usersToResetPassListPath))
        # Import the CSV file containing users and their new passwords
        $usersToResetPassList = Import-Csv $usersToResetPassListPath -Delimiter ";"        
        Write-Host "CSV file imported successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any users
        if ($usersToResetPassList.Count -eq 0) {
            [LogHandler]::Instance.ErrorWrite("No users found in the CSV file. Please fill in the file and try again.`n==========================================================")
            Write-Host "No users found in the CSV file." -ForegroundColor Yellow
        }
        # Iterate through each user in the list
        foreach ($user in $usersToResetPassList) {
            try {
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }                
                # Create a hashtable containing the user ID who needs a password reset and the new password
                $newPass = @{ 
                    "id" = $user.id 
                    "newPassword" = $user.newPassword 
                }            
                # Retrieve user details using the getUserDetails method (to get the user ID)
                $user_details = $this.getUserDetails($user, $auth_token)
                # Construct the URL for the API endpoint to reset the user's password
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Users/$($user_details.id)/ResetPassword/"
                # Convert the new password hashtable to JSON format
                $body = $newPass | ConvertTo-Json

                try {
                    # Send a POST request to reset the user's password
                    $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                    # If the request is successful (HTTP 200 OK)
                    if( $response.StatusCode -eq 200) {
                        Write-Host "Reseting Password for user <$($user_details.username)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Reseting Password for user <$($user_details.username)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Reseting Password for user <$($user_details.username)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Reseting Password for user <$($user_details.username)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while reseting password for user <$($user.username)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while reseting password for user <$($user.username)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred while reseting password for user <$($user.username)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while reseting password for user <$($user.username)> : $_.`n==========================================================")
            }
        }
        # Display a success message after reseting passwords for all users
        Write-Host "Reseting Password for all users from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Reseting Password for all users from CSV file completed successfully.`n==========================================================")
    }

###################################### Add Users ############################################################

# Method to add new users
    [void] addUsers([string] $auth_token){
        # Prompt the user for the path to the CSV file containing users to add
        $usersToAddListPath=""
        do {
            $usersToAddListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $usersToAddListPath)) {                
                Write-Host "File path <$usersToAddListPath> does not exist. Please try again" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$usersToAddListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $usersToAddListPath))
        # Import the CSV file containing users to add
        $usersToAddList = Import-Csv $usersToAddListPath -Delimiter ";"        
        Write-Host "CSV file imported successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any users
        if ($usersToAddList.Count -eq 0) {
            [LogHandler]::Instance.ErrorWrite("No users found in the CSV file. Please fill in the file and try again.`n==========================================================")
            Write-Host "No users found in the CSV file." -ForegroundColor Yellow
        }
        # Loop through each user in the list to add them 
        foreach ($user in $usersToAddList) {
            try {
    
                # authenticationMethod
                $authMethod = @()
                if ($user.authenticationMethod -and $user.authenticationMethod.Trim() -ne "") {
                    $authMethod = $user.authenticationMethod -split "," | ForEach-Object { $_.Trim() }
                }
                $authMethod = [System.Collections.ArrayList]@($authMethod)

                # allowedAuthenticationMethods
                $allowedAuth = @()
                if ($user.allowedAuthenticationMethods -and $user.allowedAuthenticationMethods.Trim() -ne "") {
                    $allowedAuth = $user.allowedAuthenticationMethods -split "," | ForEach-Object { $_.Trim() }
                }
                $allowedAuth = [System.Collections.ArrayList]@($allowedAuth)

                # unAuthorizedInterfaces
                $unauthorizedInterfaces = @()
                if ($user.unAuthorizedInterfaces -and $user.unAuthorizedInterfaces.Trim() -ne "") {
                    $unauthorizedInterfaces = $user.unAuthorizedInterfaces -split "," | ForEach-Object { $_.Trim() }
                }
                $unauthorizedInterfaces = [System.Collections.ArrayList]@($unauthorizedInterfaces)

                # vaultAuthorization
                $vaultAuth = @()
                if ($user.vaultAuthorization -and $user.vaultAuthorization.Trim() -ne "") {
                    $vaultAuth = $user.vaultAuthorization -split "," | ForEach-Object { $_.Trim() }
                }
                $vaultAuth = [System.Collections.ArrayList]@($vaultAuth)

                # Prepare the user data to be sent in the request body
                $user_data = @{
                    "username" = $user.username
                    "userType" = $user.userType
                    "initialPassword" = $user.initialPassword   #Not required for LDAP.
                    "authenticationMethod" = $authMethod
                    "allowedAuthenticationMethods" = $allowedAuth
                    "location" = $user.location
                    "unAuthorizedInterfaces" = $unauthorizedInterfaces
                    "expiryDate" = $user.expiryDate
                    "vaultAuthorization" = $vaultAuth
                    "enableUser" = $user.enableUser
                    "changePassOnNextLogon" = $user.changePassOnNextLogon
                    "passwordNeverExpires" = $user.passwordNeverExpires
                    "description" = $user.description                                        
                    "businessAddress" = @{
                        "workStreet"  = $user.workStreet
                        "workCity"    = $user.workCity
                        "workState"   = $user.workState
                        "workZip"     = $user.workZip
                        "workCountry" = $user.workCountry
                    }
                    "internet" = @{
                        "homePage"      = $user.homePage
                        "homeEmail"     = $user.homeEmail
                        "businessEmail" = $user.businessEmail
                        "otherEmail"    = $user.otherEmail
                    }
                    "phones" = @{
                        "homeNumber"     = $user.homeNumber
                        "businessNumber" = $user.businessNumber
                        "cellularNumber" = $user.cellularNumber
                        "faxNumber"      = $user.faxNumber
                        "pagerNumber"    = $user.pagerNumber
                    }
                    "personalDetails" = @{
                        "street"       = $user.street
                        "city"         = $user.city
                        "state"        = $user.state
                        "zip"          = $user.zip
                        "country"      = $user.country
                        "title"        = $user.title
                        "organization" = $user.organization
                        "department"   = $user.department
                        "profession"   = $user.profession
                        "firstName"    = $user.firstName
                        "middleName"   = $user.middleName
                        "lastName"     = $user.lastName
                    }
                }
                # Define the headers for the request, including the authorization token
                $headers = @{ 
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Construct the URL for the API endpoint to add a new user
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Users"
                # Convert the user data hashtable to JSON format
                $body = $user_data | ConvertTo-Json -Depth 10
                
                try {
                    # Send a POST request to add the new user
                    $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                    # If the request is successful (HTTP 201 Created)
                    if( $response.StatusCode -eq 201) {
                        Write-Host "Adding user <$($user.username)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Adding user <$($user.username)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Adding user <$($user.username)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Adding user <$($user.username)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch { 
                    # Catch any exceptions during the request and log them               
                    Write-Host "An error occurred while adding user <$($user.username)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while adding user <$($user.username)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred while adding user <$($user.username)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while adding user <$($user.username)> : $_.`n==========================================================")
            }
        }
        # Display a success message after adding all users
        Write-Host "Adding all users from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Adding all users from CSV file completed successfully.`n==========================================================")
    }

###################################### Update Users #########################################################

# Method to update existing users
    [void] updateUsers([string] $auth_token){
     
        # Prompt the user for the path to the CSV file containing users to update
        $usersToUpdateListPath=""
        do {
            $usersToUpdateListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $usersToUpdateListPath)) {                
                Write-Host "File path <$usersToUpdateListPath> does not exist. Please try again" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$usersToUpdateListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $usersToUpdateListPath))
        # Import the CSV file containing users to update
        $usersToUpdateList = Import-Csv $usersToUpdateListPath -Delimiter ";"        
        Write-Host "CSV file imported successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any users
        if ($usersToUpdateList.Count -eq 0) {
            [LogHandler]::Instance.ErrorWrite("No users found in the CSV file. Please fill in the file and try again.`n==========================================================")
            Write-Host "No users found in the CSV file." -ForegroundColor Yellow
        }
        # Iterate through each user in the list to update them
        foreach ($user in $usersToUpdateList) {
            try {
                # Retrieve user details using the getUserDetails method (to get the user ID)
                $user_details = $this.getUserDetails($user, $auth_token)

                ################################ FOR NEW VALUES ##############################################
                # authenticationMethod
                $authMethod = @()
                if ($user.authenticationMethod -and $user.authenticationMethod.Trim() -ne "") {
                    $authMethod = $user.authenticationMethod -split "," | ForEach-Object { $_.Trim() }
                }
                $authMethod = [System.Collections.ArrayList]@($authMethod)

                # allowedAuthenticationMethods
                $allowedAuth = @()
                if ($user.allowedAuthenticationMethods -and $user.allowedAuthenticationMethods.Trim() -ne "") {
                    $allowedAuth = $user.allowedAuthenticationMethods -split "," | ForEach-Object { $_.Trim() }
                }
                $allowedAuth = [System.Collections.ArrayList]@($allowedAuth)

                # unAuthorizedInterfaces
                $unauthorizedInterfaces = @()
                if ($user.unAuthorizedInterfaces -and $user.unAuthorizedInterfaces.Trim() -ne "") {
                    $unauthorizedInterfaces = $user.unAuthorizedInterfaces -split "," | ForEach-Object { $_.Trim() }
                }
                $unauthorizedInterfaces = [System.Collections.ArrayList]@($unauthorizedInterfaces)

                # vaultAuthorization
                $vaultAuth = @()
                if ($user.vaultAuthorization -and $user.vaultAuthorization.Trim() -ne "") {
                    $vaultAuth = $user.vaultAuthorization -split "," | ForEach-Object { $_.Trim() }
                }
                $vaultAuth = [System.Collections.ArrayList]@($vaultAuth)
                ###################################################################################################
                
                # Fetch the current values for the user in case we want to preserve them by leaving the corresponding fields blank in the CSV — otherwise, empty fields will overwrite existing data with null.
                $new_data_enableUser                = if (-not [string]::IsNullOrWhiteSpace($user.enableUser)) { $user.enableUser } else { $user_details.enableUser } 
                $new_data_changePassOnNextLogon    = if (-not [string]::IsNullOrWhiteSpace($user.changePassOnNextLogon)) { $user.changePassOnNextLogon } else { $user_details.changePassOnNextLogon }
                $new_data_expiryDate               = if (-not [string]::IsNullOrWhiteSpace($user.expiryDate)) { $user.expiryDate } else { $user_details.expiryDate }
                $new_data_suspended                = if (-not [string]::IsNullOrWhiteSpace($user.suspended)) { $user.suspended } else { $user_details.suspended }
                $new_data_unAuthorizedInterfaces   = if (-not [string]::IsNullOrWhiteSpace($user.unAuthorizedInterfaces)) { $unauthorizedInterfaces } else { $user_details.unAuthorizedInterfaces }
                $new_data_unAuthorizedInterfaces =  [System.Collections.ArrayList]@($new_data_unAuthorizedInterfaces)

                $new_data_authenticationMethod         = if (-not [string]::IsNullOrWhiteSpace($user.authenticationMethod)) { $authMethod } else { $user_details.authenticationMethod }
                $new_data_authenticationMethod =  [System.Collections.ArrayList]@($new_data_authenticationMethod)
                $new_data_allowedAuthenticationMethods = if (-not [string]::IsNullOrWhiteSpace($user.allowedAuthenticationMethods)) { $allowedAuth } else { $user_details.allowedAuthenticationMethods }
                $new_data_allowedAuthenticationMethods =  [System.Collections.ArrayList]@($new_data_allowedAuthenticationMethods)
                $new_data_passwordNeverExpires         = if (-not [string]::IsNullOrWhiteSpace($user.passwordNeverExpires)) { $user.passwordNeverExpires } else { $user_details.passwordNeverExpires }
                $new_data_distinguishedName            = if (-not [string]::IsNullOrWhiteSpace($user.distinguishedName)) { $user.distinguishedName } else { $user_details.distinguishedName }
                $new_data_description                  = if (-not [string]::IsNullOrWhiteSpace($user.description)) { $user.description } else { $user_details.description }

                $new_data_workStreet  = if (-not [string]::IsNullOrWhiteSpace($user.workStreet)) { $user.workStreet } else { $user_details.businessAddress.workStreet }
                $new_data_workCity    = if (-not [string]::IsNullOrWhiteSpace($user.workCity)) { $user.workCity } else { $user_details.businessAddress.workCity }
                $new_data_workState   = if (-not [string]::IsNullOrWhiteSpace($user.workState)) { $user.workState } else { $user_details.businessAddress.workState }
                $new_data_workZip     = if (-not [string]::IsNullOrWhiteSpace($user.workZip)) { $user.workZip } else { $user_details.businessAddress.workZip }
                $new_data_workCountry = if (-not [string]::IsNullOrWhiteSpace($user.workCountry)) { $user.workCountry } else { $user_details.businessAddress.workCountry }

                $new_data_homePage      = if (-not [string]::IsNullOrWhiteSpace($user.homePage)) { $user.homePage } else { $user_details.internet.homePage }
                $new_data_homeEmail     = if (-not [string]::IsNullOrWhiteSpace($user.homeEmail)) { $user.homeEmail } else { $user_details.internet.homeEmail }
                $new_data_businessEmail = if (-not [string]::IsNullOrWhiteSpace($user.businessEmail)) { $user.businessEmail } else { $user_details.internet.businessEmail }
                $new_data_otherEmail    = if (-not [string]::IsNullOrWhiteSpace($user.otherEmail)) { $user.otherEmail } else { $user_details.internet.otherEmail }

                $new_data_homeNumber     = if (-not [string]::IsNullOrWhiteSpace($user.homeNumber)) { $user.homeNumber } else { $user_details.phones.homeNumber }
                $new_data_businessNumber = if (-not [string]::IsNullOrWhiteSpace($user.businessNumber)) { $user.businessNumber } else { $user_details.phones.businessNumber }
                $new_data_cellularNumber = if (-not [string]::IsNullOrWhiteSpace($user.cellularNumber)) { $user.cellularNumber } else { $user_details.phones.cellularNumber }
                $new_data_faxNumber      = if (-not [string]::IsNullOrWhiteSpace($user.faxNumber)) { $user.faxNumber } else { $user_details.phones.faxNumber }
                $new_data_pagerNumber    = if (-not [string]::IsNullOrWhiteSpace($user.pagerNumber)) { $user.pagerNumber } else { $user_details.phones.pagerNumber }

                $new_data_street       = if (-not [string]::IsNullOrWhiteSpace($user.street)) { $user.street } else { $user_details.personalDetails.street }
                $new_data_city         = if (-not [string]::IsNullOrWhiteSpace($user.city)) { $user.city } else { $user_details.personalDetails.city }
                $new_data_state        = if (-not [string]::IsNullOrWhiteSpace($user.state)) { $user.state } else { $user_details.personalDetails.state }
                $new_data_zip          = if (-not [string]::IsNullOrWhiteSpace($user.zip)) { $user.zip } else { $user_details.personalDetails.zip }
                $new_data_country      = if (-not [string]::IsNullOrWhiteSpace($user.country)) { $user.country } else { $user_details.personalDetails.country }
                $new_data_title        = if (-not [string]::IsNullOrWhiteSpace($user.title)) { $user.title } else { $user_details.personalDetails.title }
                $new_data_organization = if (-not [string]::IsNullOrWhiteSpace($user.organization)) { $user.organization } else { $user_details.personalDetails.organization }
                $new_data_department   = if (-not [string]::IsNullOrWhiteSpace($user.department)) { $user.department } else { $user_details.personalDetails.department }
                $new_data_profession   = if (-not [string]::IsNullOrWhiteSpace($user.profession)) { $user.profession } else { $user_details.personalDetails.profession }
                $new_data_firstName    = if (-not [string]::IsNullOrWhiteSpace($user.firstName)) { $user.firstName } else { $user_details.personalDetails.firstName }
                $new_data_middleName   = if (-not [string]::IsNullOrWhiteSpace($user.middleName)) { $user.middleName } else { $user_details.personalDetails.middleName }
                $new_data_lastName     = if (-not [string]::IsNullOrWhiteSpace($user.lastName)) { $user.lastName } else { $user_details.personalDetails.lastName }

                $new_data_username           = if (-not [string]::IsNullOrWhiteSpace($user.newusername)) { $user.newusername } else { $user_details.username }
                $new_data_source             = if (-not [string]::IsNullOrWhiteSpace($user.source)) { $user.source } else { $user_details.source }
                $new_data_userType           = if (-not [string]::IsNullOrWhiteSpace($user.userType)) { $user.userType } else { $user_details.userType }
                $new_data_componentUser      = if (-not [string]::IsNullOrWhiteSpace($user.componentUser)) { $user.componentUser } else { $user_details.componentUser }
                $new_data_vaultAuthorization = if (-not [string]::IsNullOrWhiteSpace($user.vaultAuthorization)) { $vaultAuth } else { $user_details.vaultAuthorization }
                $new_data_vaultAuthorization =  [System.Collections.ArrayList]@($new_data_vaultAuthorization)
                $new_data_location           = if (-not [string]::IsNullOrWhiteSpace($user.location)) { $user.location } else { $user_details.location }

                # Prepare the new user data to be sent in the request body
                $NewUserData = @{
                    "enableUser"                = $new_data_enableUser
                    "changePassOnNextLogon"     = $new_data_changePassOnNextLogon
                    "expiryDate"                = $new_data_expiryDate
                    "suspended"                 = $new_data_suspended
                    "unAuthorizedInterfaces"    = $new_data_unAuthorizedInterfaces

                    "authenticationMethod"         = $new_data_authenticationMethod
                    "allowedAuthenticationMethods" = $new_data_allowedAuthenticationMethods
                    "passwordNeverExpires"         = $new_data_passwordNeverExpires
                    "distinguishedName"            = $new_data_distinguishedName
                    "description"                  = $new_data_description

                    "businessAddress" = @{
                        "workStreet"  = $new_data_workStreet
                        "workCity"    = $new_data_workCity
                        "workState"   = $new_data_workState
                        "workZip"     = $new_data_workZip
                        "workCountry" = $new_data_workCountry
                    }

                    "internet" = @{
                        "homePage"      = $new_data_homePage
                        "homeEmail"     = $new_data_homeEmail
                        "businessEmail" = $new_data_businessEmail
                        "otherEmail"    = $new_data_otherEmail
                    }

                    "phones" = @{
                        "homeNumber"     = $new_data_homeNumber
                        "businessNumber" = $new_data_businessNumber
                        "cellularNumber" = $new_data_cellularNumber
                        "faxNumber"      = $new_data_faxNumber
                        "pagerNumber"    = $new_data_pagerNumber
                    }

                    "personalDetails" = @{
                        "street"       = $new_data_street
                        "city"         = $new_data_city
                        "state"        = $new_data_state
                        "zip"          = $new_data_zip
                        "country"      = $new_data_country
                        "title"        = $new_data_title
                        "organization" = $new_data_organization
                        "department"   = $new_data_department
                        "profession"   = $new_data_profession
                        "firstName"    = $new_data_firstName
                        "middleName"   = $new_data_middleName
                        "lastName"     = $new_data_lastName
                    }

                    "id"                 = $user.id
                    "username"           = $new_data_username
                    "source"             = $new_data_source
                    "userType"           = $new_data_userType
                    "componentUser"      = $new_data_componentUser
                    "vaultAuthorization" = $new_data_vaultAuthorization
                    "location"           = $new_data_location
                }
                # Define the headers for the request, including the authorization token
                $headers = @{
                "Authorization" = $auth_token
                "Content-Type"  = "application/json"
                }
                # Construct the URL for the API endpoint to update the user
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Users/$($user_details.id)/"
                # Convert the new user data hashtable to JSON format (use -Depth 10 to ensure nested objects are fully serialized) which may contain multiple levels of nested properties
                $body = $NewUserData | ConvertTo-Json -Depth 10                
                try {
                    Write-Host "Processing updating user <$($user.username)>" -ForegroundColor Green
                    # Send a PUT request to update the user
                    $response = Invoke-WebRequest $url -Method 'PUT' -Headers $headers -Body $body  
                    # If the request is successful (HTTP 200 OK)                  
                    if( $response.StatusCode -eq 200) {
                        Write-Host "Updating user <$($user.username)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Updating user <$($user.username)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Updating user <$($user.username)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Updating user <$($user.username)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while updating user <$($user.username)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while updating user <$($user.username)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred while updating user <$($user.username)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while updating user <$($user.username)> : $_.`n==========================================================")
            }
        }
        # Display a success message after updating all users
        Write-Host "Updating all users from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Updating all users from CSV file completed successfully.`n==========================================================")
    }

###################################### Delete Users #########################################################

# Method to delete users
    [void] deleteUsers([string] $auth_token){

        # Prompt the user for the path to the CSV file containing users to delete
        $usersToDeleteListPath=""
        do {
            $usersToDeleteListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $usersToDeleteListPath)) {                
                Write-Host "File path <$usersToDeleteListPath> does not exist. Please try again" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$usersToDeleteListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $usersToDeleteListPath))
        # Import the CSV file containing users to delete
        $usersToDeleteList = Import-Csv $usersToDeleteListPath -Delimiter ";"        
        Write-Host "CSV file imported successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any users
        if ($usersToDeleteList.Count -eq 0) {            
            Write-Host "No users found in the CSV file." -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No users found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each user in the list to delete them
        foreach ($user in $usersToDeleteList) {
            try {
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Retrieve user details using the getUserDetails method (to get the user ID)
                $user_details = $this.getUserDetails($user, $auth_token)
                # Construct the URL for the API endpoint to delete the user
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Users/$($user_details.id)/"

                try {
                    # Send a DELETE request to delete the user
                    $response = Invoke-WebRequest $url -Method 'DELETE' -Headers $headers
                    # If the request is successful (HTTP 204 No Content)
                    if( $response.StatusCode -eq 204) {
                        Write-Host "Deleting user <$($user.username)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Deleting user <$($user.username)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Deleting user <$($user.username)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Deleting user <$($user.username)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while deleting user <$($user.username)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while deleting user <$($user.username)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                Write-Host "An error occurred while deleting user <$($user.username)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while deleting user <$($user.username)> : $_.`n==========================================================")
            }
        }
        # Display a success message after deleting all users
        Write-Host "Deleting all users from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Deleting all users from CSV file completed successfully.`n==========================================================")
    }
}