# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
############################################################################################################

# Import the class from the other file #######################################################################
. ./user_handler.ps1

# Define a class to handle group in CyberArk
class GroupHandler {

    # Declare a string variable to store the PVWA URL 
    [string] $pvwa_url
    # Declare an instance of UserHandler to manage user-related operations
    [UserHandler] $user_handler

    # Constructor to initialize the class (not used in this script but present for flexibility)
    GroupHandler() {}

    # Constructor to initialize the class with the PVWA URL and create an instance of UserHandler
    GroupHandler([string] $pvwa_url){
        $this.pvwa_url = $pvwa_url
        $this.user_handler = [UserHandler]::new($pvwa_url)
    }

###################################### Get All Groups ######################################################  

# Method to retrieve all groups from CyberArk
    [PSCustomObject] getAllGroups([string] $auth_token) {

        # Define the headers for the request, including the authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Construct the URL for the API endpoint to get all groups
        $url = "https://$($this.pvwa_url)/PasswordVault/API/UserGroups/"
        
        try {
            # Send a GET request to retrieve all groups
            $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers 
            # Convert the response content from JSON format
            $jsonContent = $response.Content | ConvertFrom-Json
            # Get numbers of returned groups
            $total_groups = $jsonContent.count

            Write-Host "Retrieved <$total_groups> Groups successfully." -ForegroundColor Green
            [LogHandler]::Instance.LogWrite("Retrieved <$total_groups> Groups successfully.`n==========================================================")           

            # Convert the full content (including Groups) back to JSON, depth 10 to include all fields
            $jsonOutput = $jsonContent | ConvertTo-Json -Depth 10
            # Return the JSON string containing all groups
            return $jsonOutput
        
        } catch {
            # Catch any exceptions during the request and log them
            Write-Host "An error occurred while retrieving groups : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving groups : $_.`n==========================================================")           
            return $null
        }
}

###################################### Get All Groups ######################################################

# Method to retrieve all groups with their members from CyberArk
    [PSCustomObject] getAllGroupsWithMembers([string] $auth_token) {

        # Define the headers for the request, including the authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Construct the URL for the API endpoint to get all groups with members
        $url = "https://$($this.pvwa_url)/PasswordVault/API/UserGroups?includeMembers=True"
        
        try {
            # Send a GET request to retrieve all groups with members
            $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers 
            # Convert the response content from JSON format
            $jsonContent = $response.Content | ConvertFrom-Json

            # Get numbers of returned groups
            $total_groups = $jsonContent.count
            Write-Host "Retrieved <$total_groups> Groups successfully." -ForegroundColor Green
            [LogHandler]::Instance.LogWrite("Retrieved <$total_groups> Groups successfully.`n==========================================================")           

            # Convert the full content (including Groups) back to JSON, depth 10 to include all fields
            $jsonOutput = $jsonContent | ConvertTo-Json -Depth 10
            return $jsonOutput
        
        } catch {
            # Catch any exceptions during the request and log them
            Write-Host "An error occurred while retrieving groups : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving groups : $_.`n==========================================================")           
            return $null
        }
}
###################################### Get Groups Details ###################################################### 

# Method to retrieve details of a specific group by its name
    [PSCustomObject] getGroupDetails([PSCustomObject] $group,[string] $auth_token) {

        # Define the headers for the request, including the authorization token
        $headers = @{
            "Authorization" = $auth_token
            "Content-Type"  = "application/json"
        }
        # Construct the URL for the API endpoint to retrieve group details based on the group's name
        $url = "https://$($this.pvwa_url)/PasswordVault/API/UserGroups?search=$($group.groupName)"
                
        try {
            # Send a GET request to retrieve details of the specified group
            $response = Invoke-WebRequest $url -Method 'GET' -Headers $headers
            # If the request is successful (HTTP 200 OK)
            if ($response.StatusCode -eq 200) {
                # Parse the JSON response content
                $response = ConvertFrom-Json $response
                # Check if the group exists in the response
                foreach ($result_group in $response.value) {
                    # If the group name matches the requested group name
                    if ($result_group.groupName -eq $group.groupName) { 
                        [LogHandler]::Instance.LogWrite("Retrieved all details for group : <$($result_group.groupName)> completed successfully.`n==========================================================")
                        return $result_group
                    }
                }
                Write-Host "Group : <$($group.groupName)> not found" -ForegroundColor Yellow
                [LogHandler]::Instance.ErrorWrite("Group : <$($group.groupName)> not found.")
                # return $response                
                return [PSCustomObject]@{}
            }
            else { 
                # If the request fails, display and log the error with the status code               
                Write-Host "Retrieving details for group : <$($group.groupName)> failed. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("Retrieving details for group : <$($group.groupName)> failed. Returned Status code : $($response.StatusCode).")
                return [PSCustomObject]@{}
            }
        }
        catch {
            # Catch any exceptions during the request and log them
            Write-Host "An error occurred while retrieving details for <$($group.groupName)> : $_" -ForegroundColor Red
            [LogHandler]::Instance.ErrorWrite("An error occurred while retrieving details for <$($group.groupName)> : $_.`n==========================================================")
            return [PSCustomObject]@{}
        }
}

###################################### Add Groups ######################################################  

# Method to add new groups to CyberArk
    [void] addGroups([string] $auth_token){
        # Prompt the user to enter the full path to the CSV file containing group details
        $groupsToAddListPath=""
        do {
            $groupsToAddListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $groupsToAddListPath)) {            
                Write-Host "CSV File path <$groupsToAddListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$groupsToAddListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $groupsToAddListPath))
        # Import the CSV file containing group details
        $groupsToAddList = Import-Csv $groupsToAddListPath -Delimiter ";"    
        Write-Host "CSV file imported successfully." -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any groups
        if ($groupsToAddList.Count -eq 0) {        
            Write-Host "No groups found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No groups found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each group in the list
        foreach ($group in $groupsToAddList) {

            try {
                # Prepare the group data to be sent in the request body
                $group_data = @{
                    "groupName" = $group.groupName
                    "description" = $group.description
                    "location" = $group.location               
                }
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Construct the URL for the API endpoint to add groups
                $url = "https://$($this.pvwa_url)/PasswordVault/API/UserGroups/"
                # Convert the group data to JSON format
                $body = $group_data | ConvertTo-Json -Depth 10
                try {
                    # Send a POST request to the API endpoint to add the group
                    $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                    # If the request is successful (HTTP 201 Created)
                    if( $response.StatusCode -eq 201) {
                        Write-Host "Adding group <$($group_data['groupName'])> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Adding group <$($group_data['groupName'])> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Adding group $($group_data['groupName']) ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Adding group <$($group_data['groupName'])> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while adding group <$($group_data['groupName'])> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while adding group : <$($group_data['groupName'])> : $_.`n==========================================================")
                }
            } catch {
                    # Catch any exceptions during the group addition process and log them
                    Write-Host "An error occurred while adding group <$($group.groupName)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while adding group : <$($group.groupName)> : $_.`n==========================================================")
            }
        }
        # Display a success message after processing all groups
        Write-Host "Adding all groups from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Adding all groups from CSV file completed successfully.`n==========================================================")
    }

###################################### Update Groups ###################################################### 

# Method to update existing groups in CyberArk
    [void] updateGroups([string] $auth_token){
        # Prompt the user to enter the full path to the CSV file containing group details
        $groupsToUpdateListPath=""
        do {
            $groupsToUpdateListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $groupsToUpdateListPath)) {            
                Write-Host "CSV File path <$groupsToUpdateListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$groupsToUpdateListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $groupsToUpdateListPath))
        # Import the CSV file containing group details
        $groupsListToUpdate = Import-Csv $groupsToUpdateListPath -Delimiter ";"    
        Write-Host "CSV file imported successfully." -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any groups
        if ($groupsListToUpdate.Count -eq 0) {        
            Write-Host "No groups found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No groups found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each group in the list
        foreach ($group in $groupsListToUpdate) {

            try {
                # Prepare the new group data to be sent in the request body
                $NewGroupData = @{
                        "groupName" = $group.newgroupName
                }
                # Define the headers for the request, including the authorization token
                $headers = @{
                "Authorization" = $auth_token
                "Content-Type"  = "application/json"
                }
                # Get the details of the group to be updated using the getGroupDetails method (to retrieve the user ID)
                $group_details = $this.getGroupDetails($group, $auth_token)
                # Construct the URL for the API endpoint to update the group
                $url = "https://$($this.pvwa_url)/PasswordVault/API/UserGroups/$($group_details.id)/"
                # Convert the new group data to JSON format
                $body = $NewGroupData | ConvertTo-Json -Depth 10                
                try {                    
                    Write-Host "Processing changing the name for group: <$($group.groupName)> ==> <$($group.newgroupName)>" -ForegroundColor Green    
                    # Send a PUT request to the API endpoint to update the group                
                    $response = Invoke-WebRequest $url -Method 'PUT' -Headers $headers -Body $body
                    # If the request is successful (HTTP 200 OK)
                    if( $response.StatusCode -eq 200) {
                        Write-Host "Updating group <$($group.groupName)> ==> <$($group.newgroupName)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Updating group <$($group.groupName)> ==> <$($group.newgroupName)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Updating group $($group.groupName) ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Updating group <$($group.groupName)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while updating group <$($group.groupName)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while updating group <$($group.groupName)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the group update process and log them
                Write-Host "An error occurred while updating group <$($group.groupName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while updating group <$($group.groupName)> : $_.`n==========================================================")
            }
        }
        # Display a success message after processing all groups
        Write-Host "Updating all groups from CSV file completed successfully" -ForegroundColor Green        
        [LogHandler]::Instance.LogWrite("Updating all groups from CSV file completed successfully.`n==========================================================")
    }

###################################### Delete Groups ###################################################### 

# Method to delete groups from CyberArk
    [void] deleteGroups([string] $auth_token){
        # Prompt the user to enter the full path to the CSV file containing group details
        $groupsToDeleteListPath=""
        do {
            $groupsToDeleteListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $groupsToDeleteListPath)) {            
                Write-Host "CSV File path <$groupsToDeleteListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$groupsToDeleteListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $groupsToDeleteListPath))
        # Import the CSV file containing group details        
        $groupsToDeleteList = Import-Csv $groupsToDeleteListPath -Delimiter ";"    
        Write-Host "CSV file imported successfully." -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any groups
        if ($groupsToDeleteList.Count -eq 0) {        
            Write-Host "No groups found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No groups found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each group in the list
        foreach ($group in $groupsToDeleteList) {

            try {
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Get the details of the group to be deleted using the getGroupDetails method (to retrieve the user ID)
                $group_details = $this.getGroupDetails($group, $auth_token)
                # Construct the URL for the API endpoint to delete the group
                $url = "https://$($this.pvwa_url)/PasswordVault/API/UserGroups/$($group_details.id)/"

                try {
                    # Send a DELETE request to the API endpoint to delete the group
                    $response = Invoke-WebRequest $url -Method 'DELETE' -Headers $headers
                    # If the request is successful (HTTP 204 No Content)
                    if( $response.StatusCode -eq 204) {
                        Write-Host "Deleting group <$($group.groupName)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Deleting group <$($group.groupName)> completed successfully.`n==========================================================")
                        
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Deleting group <$($group.groupName)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Deleting group <$($group.groupName)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while deleting group <$($group.groupName)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while deleting group <$($group.groupName)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the group deletion process and log them
                Write-Host "An error occurred while deleting group <$($group.groupName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while deleting group <$($group.groupName)> : $_.`n==========================================================")
            }
        }
        # Display a success message after processing all groups
        Write-Host "Deleting all groups from CSV file completed successfully" -ForegroundColor Green        
        [LogHandler]::Instance.LogWrite("Deleting all groups from CSV file completed successfully.`n==========================================================")
    }

###################################### Add Members to Groups ######################################################  

# Method to add members to groups from a CSV file
    [void] addMembersToGroups([string] $auth_token){
        
        # Prompt the user to enter the full path to the CSV file containing group member details
        $membersToAddToGroupsListPath=""
        do {
            $membersToAddToGroupsListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $membersToAddToGroupsListPath)) {            
                Write-Host "CSV File path <$membersToAddToGroupsListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$membersToAddToGroupsListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $membersToAddToGroupsListPath))
        # Import the CSV file containing group member details
        $membersToAddToGroupsList = Import-Csv $membersToAddToGroupsListPath -Delimiter ";"    
        Write-Host "CSV file imported successfully." -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any members
        if ($membersToAddToGroupsList.Count -eq 0) {        
            Write-Host "No members found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No members found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each member in the list
        foreach ($groupMember in $membersToAddToGroupsList) {

            try {
                # Prepare the group data to be sent in the request body
                $group_data = @{ 
                    "memberId" = $groupMember.username
                    "memberType" = $groupMember.memberType
                    "domainName" = $groupMember.domainName               
                }
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Get the details of the group to which the member will be added using the getGroupDetails method
                $group_details = $this.getGroupDetails($groupMember, $auth_token)             
                # Construct the URL for the API endpoint to add members to the group
                $url = "https://$($this.pvwa_url)/PasswordVault/API/UserGroups/$($group_details.id)/Members/"
                # Convert the group data to JSON format
                $body = $group_data | ConvertTo-Json -Depth 10

                try {
                    # Send a POST request to the API endpoint to add the member to the group
                    $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                    # If the request is successful (HTTP 201 Created)
                    if( $response.StatusCode -eq 201) {
                        Write-Host "Adding Member <$($groupMember.username)> to group <$($groupMember.groupName)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Adding Member <$($groupMember.username)> to group <$($groupMember.groupName)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Adding Member <$($groupMember.username)> to group <$($groupMember.groupName)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Adding Member <$($groupMember.username)> to group <$($groupMember.groupName)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while adding Member <$($groupMember.username)> to group <$($groupMember.groupName)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while adding Member <$($groupMember.username)> to group <$($groupMember.groupName)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the member addition process and log them
                Write-Host "An error occurred while adding Member <$($groupMember.username)> to group <$($groupMember.groupName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while adding Member <$($groupMember.username)> to group <$($groupMember.groupName)> : $_.`n==========================================================")
            }
        }
        # Display a success message after processing all members
        Write-Host "Adding all Members to Groups from CSV file completed successfully" -ForegroundColor Green        
        [LogHandler]::Instance.LogWrite("Adding all Members to Groups from CSV file completed successfully.`n==========================================================")
    }

###################################### Remove Members from Groups ######################################################    

# Method to remove members from groups from a CSV file
    [void] removeMembersFromGroups([string] $auth_token){
 
        # Prompt the user to enter the full path to the CSV file containing group member details
        $membersToDeleteToGroupsListPath=""
        do {
            $membersToDeleteToGroupsListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $membersToDeleteToGroupsListPath)) {            
                Write-Host "CSV File path <$membersToDeleteToGroupsListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$membersToDeleteToGroupsListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $membersToDeleteToGroupsListPath))
        # Import the CSV file containing group member details
        $membersToDeleteToGroupsList = Import-Csv $membersToDeleteToGroupsListPath -Delimiter ";"    
        Write-Host "CSV file imported successfully." -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any members
        if ($membersToDeleteToGroupsList.Count -eq 0) {        
            Write-Host "No members found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No members found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each member in the list
        foreach ($groupMember in $membersToDeleteToGroupsList) {

            try {
                # Get the user details using the getUserDetails method from the UserHandler class (to retrieve the user ID)
                $member_details = $this.user_handler.getUserDetails($groupMember, $auth_token)
                # If the user details are not found, skip to the next member
                if ($member_details -eq $null) {
                    Write-Host "Member $($groupMember.username) not found. Skipping..." -ForegroundColor Yellow
                    continue
                }
                # Prepare the group data to be sent in the request body
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Get the group details using the getGroupDetails method (to retrieve the group ID)
                $group_details = $this.getGroupDetails($groupMember, $auth_token)
                # Construct the URL for the API endpoint to remove the member from the group
                $url = "https://$($this.pvwa_url)/PasswordVault/API/UserGroups/$($group_details.id)/Members/$($groupMember.username)/"

                try {
                    # Send a DELETE request to the API endpoint to remove the member from the group
                    $response = Invoke-WebRequest $url -Method 'DELETE' -Headers $headers
                    # If the request is successful (HTTP 204 No Content)
                    if( $response.StatusCode -eq 204) {
                        Write-Host "Removing Member <$($groupMember.username)> from group <$($groupMember.groupName)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Removing Member <$($groupMember.username)> from group <$($groupMember.groupName)> completed successfully.`n==========================================================")
                    } else {
                        # If the request fails, display and log the error with the status code
                        Write-Host "Removing Member <$($groupMember.username)> from group <$($groupMember.groupName)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Removing Member <$($groupMember.username)> from group <$($groupMember.groupName)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    Write-Host "An error occurred while removing Member <$($groupMember.username)> from group <$($groupMember.groupName)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while removing Member <$($groupMember.username)> from group <$($groupMember.groupName)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the member removal process and log them
                Write-Host "An error occurred while removing Member <$($groupMember.username)> from group <$($groupMember.groupName)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while removing Member <$($groupMember.username)> from group <$($groupMember.groupName)> : $_.`n==========================================================")
            }
        }
        # Display a success message after processing all members
        Write-Host "Removing all Members from Groups from CSV file completed successfully" -ForegroundColor Green        
        [LogHandler]::Instance.LogWrite("Removing all Members from Groups from CSV file completed successfully.`n==========================================================")
    }
}