# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
##############################################################################################################

# Define a class to handle authentication and disconnection from CyberArk
class AuthHandler {

    # Declare a string variable to store the PVWA URL
    [string] $pvwa_url 

    # Constructor to initialize the AuthHandler with the PVWA URL (not used in this script but present for flexibility)
    AuthHandler() {}

    # Constructor to initialize the AuthHandler with the PVWA URL
    AuthHandler([string] $pvwa_url) 
    {
        # Store the provided PVWA URL into the class property
        $this.pvwa_url = $pvwa_url
    }

###################################### Authentication ######################################################

# Method to authenticate to CyberArk using provided username, password, and authentication method
    [string] auth([string] $username,[string] $password,[string] $auth_method) {    
        # Initialize the variable to hold the API endpoint URL
        $url = "" 
        # Display authentication start message
        write-host "`nAuthenticating ..." -ForegroundColor Cyan 
        # Define HTTP headers for the request (application/json is required by CyberArk API)
        $headers = @{
            "Content-Type"  = "application/json"
        }
        # Create the request body with the user's credentials and convert it to JSON
        $body = @{
            username = $username
            password = $password
        } | ConvertTo-Json

        # Determine the correct login endpoint based on the authentication method
        if($auth_method -eq 'CyberArk'){ 
            $url = "https://$($this.pvwa_url)/PasswordVault/API/auth/Cyberark/Logon/"
        } elseif ($auth_method -eq 'LDAP') {
            $url = "https://$($this.pvwa_url)/PasswordVault/API/auth/LDAP/Logon/"
        }
       
        try {
            # Call the REST API to authenticate
            $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
            # If authentication is successful (HTTP 200 OK)
            if( $response.StatusCode -eq 200){
                write-host "`nAuthentication succeeded" -ForegroundColor Green
                [LogHandler]::Instance.LogWrite("Authentication succeeded for <$username> using <$auth_method>.`n==========================================================")
               
                # Return the parsed JSON response containing the authentication token
                return ConvertFrom-Json $response.Content
            }else{
                # If authentication failed, display and log the error with the status code
                write-host "`nAuthentication failed. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("Authentication failed for <$username> using <$auth_method>. Returned Status code : $($response.StatusCode).`n==========================================================")
                Exit
            }
        } catch {
            # Catch any exceptions (e.g. connection issues) and log them
            write-host "`nAn error occurred while authenticating : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while authenticating : $_.`n==========================================================")
            Exit
        }
    }

###################################### Disconnection #############################################################
    
# Method to log off from the CyberArk session using the authentication token    
    [void] logOff ([string] $auth_token){
        # Display disconnection message
        write-host "Disconnecting ..." -ForegroundColor Cyan
        # Define HTTP headers with the auth token for session termination
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Define the logoff endpoint URL
        $url = "https://$($this.pvwa_url)/PasswordVault/API/Auth/Logoff/"
    
        try {
            # Send a POST request to the logoff endpoint
            $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers
            # If logoff is successful (HTTP 200 OK)
            if( $response.StatusCode -eq 200){
                write-host "Disconnecting ...[OK]" -ForegroundColor Green
                [LogHandler]::Instance.LogWrite("Disconnecting successfully.`n==========================================================")
            }else{
                # If logoff failed, display and log the error with the status code
                write-host "Disconnecting ...[FAILED]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("Disconnecting failed. Returned Status code : $($response.StatusCode).`n==========================================================")
            }
        } catch {
            # Catch any exceptions during the logoff process and log them
            write-host "An error occurred while disconnecting : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while disconnecting : $_. `n==========================================================")
        }   
    }
}