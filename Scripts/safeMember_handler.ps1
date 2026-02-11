# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
##############################################################################################################

# Define a class to handle safe members
class SafeMemberHandler {

    # Declare a string variable to store the PVWA URL
    [string] $pvwa_url
    
    # Constructor to initialize the class (not used in this script but present for flexibility)
    SafeMemberHandler() {}

    # Constructor to initialize the class with the PVWA URL
    SafeMemberHandler([string] $pvwa_url){
        $this.pvwa_url = $pvwa_url
    }

###################################### Add Members to Safes ######################################################    

# Method to add members to safes from a CSV file
    [void] addSafeMembers([string] $auth_token) {

        # Prompt the user for the path to the CSV file containing safe members to add
        $safeMembersToAddListPath=""
        do {
            $safeMembersToAddListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $safeMembersToAddListPath)) {            
                Write-Host "CSV File path <$safeMembersToAddListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$safeMembersToAddListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $safeMembersToAddListPath))
        # Import the CSV file containing safe members to add
        $safeMembersToAddList = Import-Csv $safeMembersToAddListPath -Delimiter ";"    
        Write-Host "`nCSV file imported successfully.`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any members to add
        if ($safeMembersToAddList.Count -eq 0) {        
            Write-Host "No members found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No members found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each safe member in the list
        foreach ($safeMember in $safeMembersToAddList) {
            
            try {
                # Prepare the data for the safe member to be added
                $safeMember_data = @{
                    "memberName" = $safeMember.memberName
                    "searchIn" =  $safeMember.searchIn
                    "membershipExpirationDate" = $safeMember.membershipExpirationDate
                    "permissions" = @{
                    "useAccounts" = $safeMember.useAccounts
                    "retrieveAccounts" =  $safeMember.retrieveAccounts
                    "listAccounts" =  $safeMember.listAccounts
                    "addAccounts" =  $safeMember.addAccounts
                    "updateAccountContent" =  $safeMember.updateAccountContent
                    "updateAccountProperties" =  $safeMember.updateAccountProperties
                    "initiateCPMAccountManagementOperations" =  $safeMember.initiateCPMAccountManagementOperations
                    "specifyNextAccountContent" =  $safeMember.specifyNextAccountContent
                    "renameAccounts" =  $safeMember.renameAccounts
                    "deleteAccounts" =  $safeMember.deleteAccounts
                    "unlockAccounts" =  $safeMember.unlockAccounts
                    "manageSafe" =  $safeMember.manageSafe
                    "manageSafeMembers" =  $safeMember.manageSafeMembers
                    "backupSafe" =  $safeMember.backupSafe
                    "viewAuditLog" =  $safeMember.viewAuditLog
                    "viewSafeMembers" =  $safeMember.viewSafeMembers
                    "accessWithoutConfirmation" =  $safeMember.accessWithoutConfirmation
                    "createFolders" =  $safeMember.createFolders
                    "deleteFolders" =  $safeMember.deleteFolders
                    "moveAccountsAndFolders" =  $safeMember.moveAccountsAndFolders
                    "requestsAuthorizationLevel1" =  $safeMember.requestsAuthorizationLevel1
                    "requestsAuthorizationLevel2" =  $safeMember.requestsAuthorizationLevel2
                    }
                    "MemberType" =  $safeMember.MemberType
                }
                
                write-host "`nProcessing adding safe <$($safeMember_data['memberName'])> to <$($safeMember.safeUrlId)> ...`n" -ForegroundColor Cyan              
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Construct the URL for the API endpoint to add members to safes
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Safes/$($safeMember.safeUrlId)/Members/"
                # Convert the safe member data to JSON format
                $body = $safeMember_data | ConvertTo-Json -Depth 10

                try {
                    # Send a POST request to the API endpoint to add the member to the safe
                    $response = Invoke-WebRequest $url -Method 'POST' -Headers $headers -Body $body
                    # If the request is successful, display and log a success message
                    if( $response.StatusCode -eq 201){
                        write-host "Adding member <$($safeMember_data['memberName'])> to safe <$($safeMember.safeUrlId)> ...[OK]`n" -ForegroundColor Green  
                        [LogHandler]::Instance.LogWrite("Adding member <$($safeMember_data['memberName'])> to safe <$($safeMember.safeUrlId)> completed successfully.`n==========================================================")
                    }else{
                        write-host "Adding member <$($safeMember_data['memberName'])> to safe <$($safeMember.safeUrlId)> ...[Failed]. Returned Status code : $($response.StatusCode)`n" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Adding member <$($safeMember_data['memberName'])> to safe <$($safeMember.safeUrlId)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    write-host "An error occurred while adding member <$($safeMember_data['memberName'])> to safe <$($safeMember.safeUrlId)> : $_`n" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while adding member <$($safeMember_data['memberName'])> to safe <$($safeMember.safeUrlId)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the processing of each safe member and log them
                write-host "An error occurred while adding member <$($safeMember.memberName)> to safe <$($safeMember.safeUrlId)> : $_`n" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while adding member <$($safeMember.memberName)> to safe <$($safeMember.safeUrlId)> : $_.`n==========================================================")
            }
        }       
        # Display success message after processing all safe members 
        Write-Host "Adding all members to safes from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Adding all members to safes from CSV file completed successfully.`n==========================================================")
    }

###################################### Update Safes Members ###################################################### 

# Method to update members in safes from a CSV file
    [void] updateSafeMembers([string] $auth_token){

        # Prompt the user for the path to the CSV file containing safe members to update
        $safeMembersToUpdateListPath=""
        do {
            $safeMembersToUpdateListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $safeMembersToUpdateListPath)) {            
                Write-Host "CSV File path <$safeMembersToUpdateListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$safeMembersToUpdateListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $safeMembersToUpdateListPath))
        # Import the CSV file containing safe members to update
        $safeMembersToUpdateList = Import-Csv $safeMembersToUpdateListPath -Delimiter ";"    
        Write-Host "`nCSV file imported successfully.`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any members to update
        if ($safeMembersToUpdateList.Count -eq 0) {        
            Write-Host "No members found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No members found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each safe member in the list
        foreach ($safeMember in $safeMembersToUpdateList) {

            try {
                # Prepare the data for the safe member to be updated
                $safeMember_data = @{
                "membershipExpirationDate" = $safeMember.membershipExpirationDate
                "permissions" = @{
                    "useAccounts" = $safeMember.useAccounts
                    "retrieveAccounts" =  $safeMember.retrieveAccounts
                    "listAccounts" =  $safeMember.listAccounts
                    "addAccounts" =  $safeMember.addAccounts
                    "updateAccountContent" =  $safeMember.updateAccountContent
                    "updateAccountProperties" =  $safeMember.updateAccountProperties
                    "initiateCPMAccountManagementOperations" =  $safeMember.initiateCPMAccountManagementOperations
                    "specifyNextAccountContent" =  $safeMember.specifyNextAccountContent
                    "renameAccounts" =  $safeMember.renameAccounts
                    "deleteAccounts" =  $safeMember.deleteAccounts
                    "unlockAccounts" =  $safeMember.unlockAccounts
                    "manageSafe" =  $safeMember.manageSafe
                    "manageSafeMembers" =  $safeMember.manageSafeMembers
                    "backupSafe" =  $safeMember.backupSafe
                    "viewAuditLog" =  $safeMember.viewAuditLog
                    "viewSafeMembers" =  $safeMember.viewSafeMembers
                    "accessWithoutConfirmation" =  $safeMember.accessWithoutConfirmation
                    "createFolders" =  $safeMember.createFolders
                    "deleteFolders" =  $safeMember.deleteFolders
                    "moveAccountsAndFolders" =  $safeMember.moveAccountsAndFolders
                    "requestsAuthorizationLevel1" =  $safeMember.requestsAuthorizationLevel1
                    "requestsAuthorizationLevel2" =  $safeMember.requestsAuthorizationLevel2
                }
            }
            write-host "`nProcessing updating <$($safeMember.memberName)> inside safe <$($safeMember.safeUrlId)> ...`n"  -ForegroundColor Cyan
            # Define the headers for the request, including the authorization token
            $headers = @{
                "Authorization" = $auth_token
                "Content-Type"  = "application/json"
            }
            # Construct the URL for the API endpoint to update members in safes
            $url = "https://$($this.pvwa_url)/PasswordVault/API/Safes/$($safeMember.safeUrlId)/Members/$($safeMember.memberName)/"
            # Convert the safe member data to JSON format
            $body = $safeMember_data | ConvertTo-Json -Depth 10

            try {
                # Send a PUT request to the API endpoint to update the member in the safe
                $response = Invoke-WebRequest $url -Method 'PUT' -Headers $headers -Body $body
                # If the request is successful (HTTP 200 OK)
                if( $response.StatusCode -eq 200){
                    write-host "Updating member <$($safeMember.memberName)> inside safe <$($safeMember.safeUrlId)> ...[OK]" -ForegroundColor Green
                    [LogHandler]::Instance.LogWrite("Updating member <$($safeMember.memberName)> inside safe <$($safeMember.safeUrlId)> completed successfully.`n==========================================================")
                }else{
                    # If the request fails, display and log the error with the status code
                    write-host "Updating member <$($safeMember.memberName)> inside safe <$($safeMember.safeUrlId)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("Updating member <$($safeMember.memberName)> inside safe <$($safeMember.safeUrlId)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the request and log them
                write-host "An error occurred while updating member <$($safeMember.memberName)> inside safe <$($safeMember.safeUrlId)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while updating member <$($safeMember.memberName)> inside safe <$($safeMember.safeUrlId)> : $_.`n==========================================================")
            }
            } catch {
            # Catch any exceptions during the processing of each safe member and log them
                write-host "An error occurred while updating member <$($safeMember.memberName)> inside safe <$($safeMember.safeUrlId)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while updating member <$($safeMember.memberName)> inside safe <$($safeMember.safeUrlId)> : $_.`n==========================================================")
            }
        }
        # Display success message after processing all safe members
        Write-Host "`nUpdating all members inside safes from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Updating all members inside safes from CSV file completed successfully.`n==========================================================")
    }

###################################### Delete Safes Members ###################################################### 

# Method to delete members from safes from a CSV file
    [void] deleteSafeMembers([string] $auth_token){

        # Prompt the user for the path to the CSV file containing safe members to delete
        $safeMembersToDeleteListPath=""
        do {
            $safeMembersToDeleteListPath = Read-Host "Please enter full path to your CSV file (separated with ';')"

            if (-not (Test-Path $safeMembersToDeleteListPath)) {            
                Write-Host "CSV File path <$safeMembersToDeleteListPath> does not exist. Please try again." -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("CSV File path <$safeMembersToDeleteListPath> does not exist. Please try again.`n==========================================================")
            }
        } while (-not (Test-Path $safeMembersToDeleteListPath))
        # Import the CSV file containing safe members to delete
        $safeMembersToDeleteList = Import-Csv $safeMembersToDeleteListPath -Delimiter ";"    
        Write-Host "`nCSV file imported successfully.`n" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("CSV file imported successfully.`n==========================================================")
        # Check if the CSV file contains any members to delete
        if ($safeMembersToDeleteList.Count -eq 0) {        
            Write-Host "No members found in the CSV file" -ForegroundColor Yellow
            [LogHandler]::Instance.ErrorWrite("No members found in the CSV file. Please fill in the file and try again.`n==========================================================")
        }
        # Iterate through each safe member in the list
        foreach ($safeMember in $safeMembersToDeleteList) {

            try {
                write-host "`nProcessing Deleting safe $($safeMember.memberName) from $($safeMember.safeUrlId) ...`n" -ForegroundColor Cyan
                # Define the headers for the request, including the authorization token
                $headers = @{
                    "Authorization" = $auth_token
                    "Content-Type"  = "application/json"
                }
                # Construct the URL for the API endpoint to delete members from safes
                $url = "https://$($this.pvwa_url)/PasswordVault/API/Safes/$($safeMember.safeUrlId)/Members/$($safeMember.memberName)/"

                try {
                    # Send a DELETE request to the API endpoint to delete the member from the safe
                    $response = Invoke-WebRequest $url -Method 'DELETE' -Headers $headers
                    # If the request is successful (HTTP 204 No Content)
                    if( $response.StatusCode -eq 204){
                        write-host "Deleting member <$($safeMember.memberName)> from <$($safeMember.safeUrlId)> ...[OK]" -ForegroundColor Green
                        [LogHandler]::Instance.LogWrite("Deleting member <$($safeMember.memberName)> from safe <$($safeMember.safeUrlId)> completed successfully.`n==========================================================")
                    }else{
                        # If the request fails, display and log the error with the status code
                        write-host "Deleting member <$($safeMember.memberName)> from <$($safeMember.safeUrlId)> ...[Failed]. Returned Status code : $($response.StatusCode)" -ForegroundColor Red
                        [LogHandler]::Instance.ErrorWrite("Deleting member <$($safeMember.memberName)> from safe <$($safeMember.safeUrlId)> failed. Returned Status code : $($response.StatusCode).`n==========================================================")
                    }
                } catch {
                    # Catch any exceptions during the request and log them
                    write-host "An error occurred while deleting member <$($safeMember.memberName)> from <$($safeMember.safeUrlId)> : $_" -ForegroundColor Red
                    [LogHandler]::Instance.ErrorWrite("An error occurred while deleting member <$($safeMember.memberName)> from <$($safeMember.safeUrlId)> : $_.`n==========================================================")
                }
            } catch {
                # Catch any exceptions during the processing of each safe member and log them
                write-host "An error occurred while deleting member <$($safeMember.memberName)> from <$($safeMember.safeUrlId)> : $_" -ForegroundColor Red
                [LogHandler]::Instance.ErrorWrite("An error occurred while deleting member <$($safeMember.memberName)> from <$($safeMember.safeUrlId)> : $_.`n==========================================================")
            }
        }
        # Display success message after processing all safe members
        Write-Host "`nDeleting all members from safes from CSV file completed successfully" -ForegroundColor Green
        [LogHandler]::Instance.LogWrite("Deleting all members from safes from CSV file completed successfully.`n==========================================================")
    }
}