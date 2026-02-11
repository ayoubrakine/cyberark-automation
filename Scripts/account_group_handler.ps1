# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
##############################################################################################################

# Import the class from the other file #######################################################################
. ./account_handler.ps1

# Define class to handle account group in CyberArk
class AccountGroupHandler {

    # Declare a string variable to store the PVWA URL
    [string] $pvwa_url
    # Declare an instance of AccountHandler to handle account operations
    [AccountHandler] $account_handler

    # Constructor to initialize the class (not used in this script but present for flexibility)
    AccountGroupHandler() {}

    # Constructor to initialize the AccountGroupHandler with the PVWA URL
    AccountGroupHandler([string] $pvwa_url){
        $this.pvwa_url = $pvwa_url 
        # Initialize the AccountHandler with the provided PVWA URL
        $this.account_handler = [AccountHandler]::new($pvwa_url)
    }

####################################### Get all Account Groups By Safe ############################################# 

# This method retrieves all account groups from safes specified in a CSV file
    [void] getAccountGroupsBySafe([string] $auth_token) {
       
# Prompt the user to enter the path to the CSV file containing safe names
        $safesListPath=""
        do {
            $safesListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $safesListPath)) {            
                Write-Host "CSV File path <$safesListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$safesListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $safesListPath))
        # Import the CSV file containing safe names
        $safesList = Import-Csv $safesListPath -Delimiter ";"    
        Write-Host "CSV file imported successfully." -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any safes
        if ($safesList.Count -eq 0) {        
            Write-Host "No safe found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No safe found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each safe in the CSV file
        foreach ($safe in $safesList) {
            
            try {
                # Prepare the headers for the API request
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }  
                # Construct the URL to retrieve account groups for the specified safe
                $url = "https://$($this.pvwa_url)/PasswordVault/API/AccountGroups?safe=$($safe.SafeName)"
                # Make the API request to retrieve account groups                 
                $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers                
                # Check if the response status code is 200 (OK)
                if( $response.StatusCode -eq 200) {     
                    # Convert the response content from JSON to a PowerShell object
                    $jsonContent = $response.Content | ConvertFrom-Json
                    # Convert the JSON content back to a JSON string with a depth of 10 to include all fields
                    $jsonOutput = $jsonContent | ConvertTo-Json -Depth 10
                    if ($jsonOutput -eq $null) {
                        Write-Host "No account groups found in the safe <$($safe.SafeName)>" -ForegroundColor Yellow
                        [LogHandler]::Instance.ErrorWrite("No account groups found in the safe <$($safe.SafeName)>.`n==========================================================")                        
                    }else {
                        # Write the success message to the console and log file
                        Write-Host "Retrieved all account groups in the safe <$($safe.SafeName)> ...[OK]" -ForegroundColor Cyan
                        [LogHandler]::Instance.ErrorWrite("Retrieved all account groups in the safe <$($safe.SafeName)> completed successfully.`n==========================================================")                               
                        Write-Host "$jsonOutput" -ForegroundColor Green
                    }
                    # Log the success message
                    # Write-Host "Retrieved all account groups in the safe <$($safe.SafeName)> ...[OK]" -ForegroundColor Green
                    # [LogHandler]::Instance.LogWrite("Retrieved all account groups in the safe <$($safe.SafeName)> successfully.`n==========================================================")           
                    # Convert the full content (including Groups) back to JSON, depth 10 to include all fields
                    # $jsonOutput = $jsonContent | ConvertTo-Json -Depth 10
                    # return $jsonOutput
                    # $jsonContent = $response.Content | ConvertFrom-Json
                    #Write-Host "response : $response"                  
                    # return $response.content
                } else {
                    # Write the failure message to the console and log file
                    Write-Host "Retrieved all account groups in the safe <$($safe.SafeName)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("Retrieved all account groups in the safe <$($safe.SafeName)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")                    
                }                                 
            } catch {
                # Handle any errors that occur during the API request
                Write-Host "An error occurred while retrieving account groups inside safe <$($safe.SafeName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving account groups inside safe <$($safe.SafeName)> : $_.`n==========================================================")                           
            }            
        }
        # Write the success message to the console and log file
        Write-Host "`nRetrieving all account groups inside safes mentioned in the CSV file was completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Retrieving all account groups inside safes mentioned in the CSV file was completed successfully.`n==========================================================")        
    }

####################################### Get all Account Groups By Safe NAME ############################################# 

# This method retrieves all account groups from a specific safe by its name
    [PSCustomObject] getAccountGroupsBySafeName([string] $SafeName, [string] $auth_token) {
        
        try {
            # Prepare the headers for the API request
            $headers = @{
                "Authorization" = $auth_token
                "Content-Type"  = "application/json"
            }
            # Construct the URL to retrieve account groups for the specified safe
            $url = "https://$($this.pvwa_url)/PasswordVault/API/AccountGroups?Safe=$SafeName"
            # Make the API request to retrieve account groups            
            $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers         
            # Check if the response status code is 200 (OK)
            if( $response.StatusCode -eq 200) {
                # Write-Host "Retrieved all account groups in the safe <$SafeName> ...[OK]" -ForegroundColor Green
                # [LogHandler]::Instance.LogWrite("Retrieved all account groups in the safe <$SafeName> successfully.`n==========================================================")           
                # Convert the full content (including Groups) back to JSON, depth 10 to include all fields
                # $jsonOutput = $jsonContent | ConvertTo-Json -Depth 10
                # return $jsonOutput
                # $jsonContent = $response.Content | ConvertFrom-Json
                # Convert the response content from JSON to a PowerShell object
                $jsonContent = $response.Content | ConvertFrom-Json
                # Convert the JSON content back to a JSON string with a depth of 10 to include all fields
                $jsonOutput = $jsonContent | ConvertTo-Json -Depth 10
                # Check if the JSON output is null (no account groups found)
                if ($jsonOutput -eq $null) {
                    Write-Host "No account groups found in the safe <$SafeName>." -ForegroundColor Yellow
                    [LogHandler]::Instance.ErrorWrite("No account groups found in the safe <$SafeName>.`n==========================================================")
                    return [PSCustomObject]@{}
                }else {
                    # Write the success message to the console and log file
                    Write-Host "Retrieved all account groups in the safe <$SafeName> ...[OK]" -ForegroundColor Green
                    [LogHandler]::Instance.LogWrite("Retrieved all account groups in the safe <$SafeName> successfully.`n==========================================================")         
                    return $jsonOutput  
                }            
            }                                 
        } catch {
            # Handle any errors that occur during the API request
            Write-Host "An error occurred while retrieving account groups inside safe <$SafeName> : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving account groups inside safe <$SafeName> : $_.`n==========================================================")           
            return $null
        }        
    return [PSCustomObject]@{}
    
    }
####################################### Get all Account Groups Members #############################################

# This method retrieves all members of account groups from a CSV file containing group names and safe names
    [PSCustomObject] getAccountGroupsMembers([string] $auth_token) {
        
        # Prompt the user to enter the path to the CSV file containing account group names and safe names
        $groupsListPath=""
        do {
            $groupsListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $groupsListPath)) {            
                Write-Host "CSV File path <$groupsListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$groupsListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $groupsListPath))
        # Import the CSV file containing account group names and safe names
        $groupsList = Import-Csv $groupsListPath -Delimiter ";"    
        Write-Host "CSV file imported successfully`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any account groups
        if ($groupsList.Count -eq 0) {        
            Write-Host "No account group found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No account group found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each account group in the CSV file
        foreach ($account_group in $groupsList) {
            
            try {
                # Prepare the headers for the API request
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Retrieve account group details by safe name using the method defined earlier                       
                $group_details = $this.getAccountGroupsBySafeName($account_group.safeName, $auth_token)
                # Convert the JSON content to a PowerShell object
                $groupList = $group_details | ConvertFrom-Json
                # Check if the account group exists in the retrieved list
                foreach ($acc_grp in $groupList) {
                    # If the group name matches the one in the CSV file, proceed to retrieve its members
                    if($account_group.GroupName -eq $acc_grp.GroupName){
                        $url = "https://$($this.pvwa_url)/PasswordVault/API/AccountGroups/$($acc_grp.GroupID)/Members/"    
                        # Make the API request to retrieve members of the account group                                
                        $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers 
                        # Check if the response status code is 200 (OK)
                        if( $response.StatusCode -eq 200) {
                            $jsonContent = $response.Content | ConvertFrom-Json
                            $jsonOutput = $jsonContent | ConvertTo-Json -Depth 10
                            # Check if the JSON output is null (no members found)
                            if ($jsonOutput -eq $null) {
                                Write-Host "No members found for account group <$($account_group.GroupName)>." -ForegroundColor Yellow
                                [LogHandler]::Instance.ErrorWrite("No members found for account group <$($account_group.GroupName)>.`n==========================================================")
                                return [PSCustomObject]@{}
                            }else{
                            # Write the success message to the console and log file
                            Write-Host "Retrieved all members for account group <$($account_group.GroupName)> ...[OK]" -ForegroundColor Green
                            [LogHandler]::Instance.LogWrite("Retrieved all members for account group <$($account_group.GroupName)> successfully.`n==========================================================")                                                                                                                           
                            return $jsonOutput
                            }
                        } else {
                            # Write the failure message to the console and log file
                            Write-Host "Retrieved all members for account group <$($account_group.GroupName)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                            [LogHandler]::Instance.ErrorWrite("Retrieved all members for account group <$($account_group.GroupName)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                            return [PSCustomObject]@{}
                        }
                }
                else {
                    # Write the failure message to the console and log file if the account group is not found
                    Write-Host "Account group  <$($account_group.GroupName)> not found" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("Account group  <$($account_group.GroupName)> not found.`n==========================================================")
                    return [PSCustomObject]@{}
                    }                                               
             }  
         
        }catch {
            # Handle any errors that occur during the API request
            Write-Host "An error occurred while retrieving members for account group <$($account_group.GroupName)> : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving members for account group <$($account_group.GroupName)> : $_.`n==========================================================")           
            return [PSCustomObject]@{}
        }        
     }  
    # Write the success message to the console and log file
    Write-Host "Retrieving members for account groups in the CSV file was completed successfully" -ForegroundColor Green
    [LogHandler]::Instance.LogWrite("Retrieving members for account groups with existing IDs in the CSV file was completed successfully.`n==========================================================")
    return [PSCustomObject]@{}
    }

###################################### Add Account Groups ######################################################  

# This method adds account groups from a CSV file to the CyberArk vault
    [void] addAccountGroups([string] $auth_token){
        
        # Prompt the user to enter the path to the CSV file containing account group details
        $accountgroupsToAddListPath=""
        do {
            $accountgroupsToAddListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $accountgroupsToAddListPath)) {            
                Write-Host "CSV File path <$accountgroupsToAddListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$accountgroupsToAddListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $accountgroupsToAddListPath))
        # Import the CSV file containing account group details
        $accountgroupsToAddList = Import-Csv $accountgroupsToAddListPath -Delimiter ";"    
        Write-Host "CSV file imported successfully`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any account groups
        if ($accountgroupsToAddList.Count -eq 0) {        
            Write-Host "No account groups found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No account groups found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each account group in the CSV file
        foreach ($account_group in $accountgroupsToAddList) {
            
            try {
                # Prepare the data for the account group to be added
                $account_group_data = @{
                    "GroupName" = $account_group.GroupName
                    "GroupPlatformID" = $account_group.GroupPlatformID
                    "Safe" = $account_group.Safe               
                }
                # Prepare the headers for the API request
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Construct the URL to add the account group
                $url = "https://$($this.pvwa_url)/PasswordVault/API/AccountGroups/"
                # Convert the account group data to JSON format with a depth of 10 to include all fields
                $body = $account_group_data | ConvertTo-Json -Depth 10
                try {
                    # Make the API request to add the account group
                    $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                    # Check if the response status code is 201 (Created)
                    if( $response.StatusCode -eq 201) {
                        Write-Host "Adding account group <$($account_group_data['GroupName'])> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Adding account group <$($account_group_data['GroupName'])> completed successfully.`n==========================================================")
                    } else {
                        # Write the failure message to the console and log file if the account group could not be added
                        Write-Host "Adding account group $($account_group_data['GroupName']) ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Adding account group <$($account_group_data['GroupName'])> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Handle any errors that occur during the API request to add the account group
                    Write-Host "An error occurred while adding account group <$($account_group.GroupName)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while adding account group : <$($account_group.GroupName)> : $_.`n==========================================================")
                }
            } catch {
                # Handle any errors that occur during the preparation of the account group data
                Write-Host "An error occurred while adding account group  <$($account_group.GroupName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while adding account group :  <$($account_group.GroupName)> : $_.`n==========================================================")
            }
        }
        # Write the success message to the console and log file
        Write-Host "Adding all account groups from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Adding all account groups from CSV file completed successfully.`n==========================================================")
    }

##################################### Add Members to Account Groups ######################################################  

# This method adds members to account groups from a CSV file
    [void] addMembersToAccountGroups([string] $auth_token){
     
        # Prompt the user to enter the path to the CSV file containing account group members
        $accountaccountgroupsListToAdd=""
        do {
            $accountaccountgroupsListToAdd = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $accountaccountgroupsListToAdd)) {            
                Write-Host "CSV File path <$accountaccountgroupsListToAdd> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$accountaccountgroupsListToAdd> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $accountaccountgroupsListToAdd))
        # Import the CSV file containing account group members
        $membersToAddToAccountGroupsList = Import-Csv $accountaccountgroupsListToAdd -Delimiter ";"    
        Write-Host "CSV file imported successfully`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any members to add
        if ($membersToAddToAccountGroupsList.Count -eq 0) {        
            Write-Host "No members found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No members found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each member in the CSV file   
        foreach ($account_group in $membersToAddToAccountGroupsList) {

            try {
                # Retrieve account details for the member using the AccountHandler instance      
                $account_details = $this.account_handler.getAccountDetails($account_group, $auth_token)
                # Check if the account details were retrieved successfully
                if ($account_details -eq $null) {
                    Write-Host "Member $($account_group.userName) not found. Skipping..." -ForegroundColor Yellow
                    continue
                }
                # Retrieve account group details by safe name using the method defined earlier
                $group_details = $this.getAccountGroupsBySafeName($account_group.safeName, $auth_token)
                # Convert the JSON content to a PowerShell object
                $groupList = $group_details | ConvertFrom-Json
                # Iterate through each account group in the retrieved list
                foreach ($acc_grp in $groupList) {
                    # If the group name matches the one in the CSV file, proceed to add the member
                    if($acc_grp.GroupName -eq $account_group.GroupName){
                        # Prepare the data for the account group member to be added
                        $account_group_data = @{
                            "AccountID" = $account_details.id           
                        }
                        # Prepare the headers for the API request
                        $headers = @{
                            "Authorization" = $auth_token
                            "Content-Type"  = "application/json"
                        }
                        # Construct the URL to add the member to the account group
                        $url = "https://$($this.pvwa_url)/PasswordVault/API/AccountGroups/$($acc_grp.GroupID)/Members/"
                        # Convert the account group member data to JSON format with a depth of 10 to include all fields
                        $body = $account_group_data | ConvertTo-Json -Depth 10

                        try {
                            # Make the API request to add the member to the account group
                            $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body                    
                            if( $response.StatusCode -eq 200) {
                                # Write the success message to the console and log file
                                Write-Host "Adding Member <$($account_group.userName)> to group <$($account_group.GroupName)> ...[OK]" -ForegroundColor Green
                                [LogHandler]::Instance.LogWrite("Adding Member <$($account_group.userName)> to group <$($account_group.GroupName)> completed successfully.`n==========================================================")
                            } else {
                                # Write the failure message to the console and log file if the member could not be added
                                Write-Host "Adding Member <$($account_group.userName)> to group <$($account_group.GroupName)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                                [LogHandler]::Instance.ErrorWrite("Adding Member <$($account_group.userName)> to group <$($account_group.GroupName)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                            }
                        } catch {
                            # Handle any errors that occur during the API request to add the member
                            Write-Host "An error occurred while adding Member <$($account_group.userName)> to group <$($account_group.GroupName)> : $_" -ForegroundColor Red
                            [LogHandler]::Instance.ErrorWrite("An error occurred while adding Member <$($account_group.userName)> to group <$($account_group.GroupName)> : $_.`n==========================================================")
                        }
                    }else {
                        # Write the failure message to the console and log file if the account group is not found
                        Write-Host "Account group  <$($account_group.GroupName)> not found" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Account group  <$($account_group.GroupName)> not found.`n==========================================================")
                          }
                }
            } catch {
                # Handle any errors that occur during the preparation of the account group member data
                Write-Host "An error occurred while adding Member <$($account_group.userName)> to group <$($account_group.GroupName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while adding Member <$($account_group.userName)> to group <$($account_group.GroupName)> : $_.`n==========================================================")
            }
        }
        # Write the success message to the console and log file
        Write-Host "`nAdding all Members to Groups from CSV file completed successfully`n" -ForegroundColor Green        
        [LogHandler]::Instance.LogWrite("Adding all Members to Groups from CSV file completed successfully.`n==========================================================")
    }

####################################### Remove Members from Groups ######################################################    

# This method removes members from account groups based on a CSV file containing member details
    [void] removeMembersFromAccountGroups([string] $auth_token){
        
        # Prompt the user to enter the path to the CSV file containing members to be removed from account groups
        $membersToDeleteToFromAccountGroupsListPath=""
        do {
            $membersToDeleteToFromAccountGroupsListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $membersToDeleteToFromAccountGroupsListPath)) {            
                Write-Host "CSV File path <$membersToDeleteToFromAccountGroupsListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$membersToDeleteToFromAccountGroupsListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $membersToDeleteToFromAccountGroupsListPath))
        # Import the CSV file containing members to be removed from account groups
        $membersToDeleteToFromAccountGroupsList = Import-Csv $membersToDeleteToFromAccountGroupsListPath -Delimiter ";"    
        Write-Host "CSV file imported successfully`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any members to delete
        if ($membersToDeleteToFromAccountGroupsList.Count -eq 0) {        
            Write-Host "No members found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No members found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each member in the CSV file
        foreach ($account_group in $membersToDeleteToFromAccountGroupsList) {
            
            try {
                # Retrieve account details for the member using the AccountHandler instance
                $account_details = $this.account_handler.getAccountDetails($account_group, $auth_token)
                # Check if the account details were retrieved successfully
                if ($account_details -eq $null) {
                    Write-Host "Member $($account_group.userName) not found. Skipping..." -ForegroundColor Yellow
                    continue
                }
                # Retrieve account group details by safe name using the method defined earlier
                $group_details = $this.getAccountGroupsBySafeName($account_group.safeName, $auth_token)
                # Convert the JSON content to a PowerShell object
                $groupList = $group_details | ConvertFrom-Json
                # Iterate through each account group in the retrieved list
                foreach ($acc_grp in $groupList) {
                    # If the group name matches the one in the CSV file, proceed to remove the member
                    if($acc_grp.GroupName -eq $account_group.GroupName){
                        # Prepare the headers for the API request
                        $headers = @{
                            "Authorization" = $auth_token
                            "Content-Type"  = "application/json"
                        }            
                        # Construct the URL to remove the member from the account group
                        $url = "https://$($this.pvwa_url)/PasswordVault/API/AccountGroups/$($acc_grp.GroupID)/Members/$($account_details.id)/"

                        try {
                            # Make the API request to remove the member from the account group
                            $response = Invoke-WebRequest $url -Method 'DELETE' -Headers $headers
                            if( $response.StatusCode -eq 204) {
                                Write-Host "Removing Member <$($account_group.userName)> from group <$($account_group.GroupName)> ...[OK]" -ForegroundColor Green
                                [LogHandler]::Instance.LogWrite("Removing Member <$($account_group.userName)> from group <$($account_group.GroupName)> completed successfully.`n==========================================================")
                            } else {
                                # Write the failure message to the console and log file if the member could not be removed
                                Write-Host "Removing Member <$($account_group.userName)> from group <$($account_group.GroupName)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                                [LogHandler]::Instance.ErrorWrite("Removing Member <$($account_group.userName)> from group <$($account_group.GroupName)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                            }
                        } catch {
                            # Handle any errors that occur during the API request to remove the member
                            Write-Host "An error occurred while removing Member <$($account_group.userName)> from group <$($account_group.GroupName)> : $_" -ForegroundColor Red
                            [LogHandler]::Instance.ErrorWrite("An error occurred while removing Member <$($account_group.userName)> from group <$($account_group.GroupName)> : $_.`n==========================================================")
                        }
                    }
                    else {
                        # Write the failure message to the console and log file if the account group is not found
                        Write-Host "Account group  <$($account_group.GroupName)> not found" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Account group  <$($account_group.GroupName)> not found.`n==========================================================")
                    }
                }
            } catch {
                # Handle any errors that occur during the preparation of the account group member data
                Write-Host "An error occurred while removing Member <$($account_group.userName)> from group <$($account_group.GroupName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while removing Member <$($account_group.userName)> from group <$($account_group.GroupName)> : $_.`n==========================================================")
            }
        }
        # Write the success message to the console and log file
        Write-Host "`nRemoving all Members from Groups from CSV file completed successfully`n" -ForegroundColor Green        
        [LogHandler]::Instance.LogWrite("Removing all Members from Groups from CSV file completed successfully.`n==========================================================")
    }
}