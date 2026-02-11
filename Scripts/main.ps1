# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
##############################################################################################################

# Import the classes from the other file #####################################################################
. ./log_handler.ps1
. ./auth_handler.ps1
. ./systemHealth_handler.ps1
. ./account_handler.ps1
. ./account_group_handler.ps1
. ./safe_handler.ps1
. ./safeMember_handler.ps1
. ./platform_handler.ps1
. ./user_handler.ps1
. ./group_handler.ps1
. ./connection_component_handler.ps1
. ./cpm_actions.ps1

###################################### Get PVWA URL #########################################################

# Define a class to get the PVWA URL from the user
function GetPvwaUrl {

    while ($true) {

        Write-Host "        
            __   _ ________      ________ _____  _    _          _____ _  __
            | \ | |  ____\ \    / |  ____|  __ \| |  | |   /\   / ____| |/ /
            |  \| | |__   \ \  / /| |__  | |__) | |__| |  /  \ | |    | ' / 
            | . ` |  __|   \ \/ / |  __| |  _  /|  __  | / /\ \| |    |  <  
            | |\  | |____   \  /  | |____| | \ \| |  | |/ ____ | |____| . \ 
            |_| \_|______|   \/   |______|_|  \_|_|  |_/_/    \_\_____|_|\_\
                                                                            
" -ForegroundColor Magenta

        Write-Host "        
            _________        ___.                   _____         __    
            \_   ___ \___.__.\_ |__   ___________  /  _  \_______|  | __
            /    \  \<   |  | | __ \_/ __ \_  __ \/  /_\  \_  __ \  |/ /
            \     \___\___  | | \_\ \  ___/|  | \/    |    \  | \/    < 
            \______  / ____| |___  /\___  >__|  \____|__  /__|  |__|_ \
                    \/\/          \/     \/              \/           \/

" -ForegroundColor DarkBlue

        Write-Host "
               ___                     __         ___   ___    __ __   ____ _  __ ____
              / _ | __ __ ___  __ __  / /        / _ \ / _ |  / //_/ /_  _// |/ // __/
             / __ |/ // // _ \/ // / / _ \      / , _// __ | / ,<   _/ /  /    // _/  
            /_/ |_|\_, / \___/\_,_/ /_.__/     /_/|_|/_/ |_|/_/|_| /___/ /_/|_//___/  
                  /___/                                                                    
"

Write-Host "======================================================================================================`n"

Write-Host "==========================================" -ForegroundColor DarkGray
Write-Host "         PVWA URL" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor DarkGray

Write-Host "`nPlease enter the PVWA URL (e.g., comp01.acme.corp)" -ForegroundColor Cyan
Write-Host "Or type [X] to Exit" -ForegroundColor Cyan

$pvwa_url = Read-Host "`n> "

        while ($true) {
            # Check if the user input is empty or whitespace
            if ([string]::IsNullOrWhiteSpace($pvwa_url)) {
                Write-Host "`n[!] No PVWA url found, please enter a valid PVWA url." -ForegroundColor Yellow
                [LogHandler]::Instance.ErrorWrite("No PVWA url found, please enter a valid PVWA url.`n==========================================================")
            }
            # Check if the user input is 'X' to exit
            elseif ($pvwa_url.ToUpper() -eq 'X') {
                Write-Host "`nExiting program..." -ForegroundColor Cyan
                Exit
            }
            # Check if the user input is a valid URL format
            else {
                $validate_choice = Read-Host "`nAre you sure you want to use this PVWA url <https://$pvwa_url/PasswordVault> ? (Y/N) "
                if ($validate_choice.ToUpper() -eq 'Y') {
                    Write-Host "`n[+] Using PVWA url <https://$pvwa_url/PasswordVault>" -ForegroundColor Green
                    [LogHandler]::Instance.LogWrite("Using PVWA url <https://$pvwa_url/PasswordVault>.`n==========================================================")
                    return $pvwa_url
                } elseif ($validate_choice.ToUpper() -eq 'N') {
                    Write-Host "`n[!] Please enter your new valid PVWA url:" -ForegroundColor Yellow
                } else {
                    Write-Host "`n[!] Invalid choice, please enter Y or N." -ForegroundColor Red
                    continue
                }
            }

            # Prompt the user to enter a new PVWA URL
            $pvwa_url = Read-Host "New PVWA url (or tap [X] to Exit)"
        }
    }
}

###################################### Loading With Bar #########################################################

# Function to show a loading bar with a percentage completion
function Show-LoadingWithBar {
    $totalSteps = 50
    $barLength   = 100
    $delayMs     = 500 / $totalSteps  # 10 ms per iteration for total of 500 ms

    for ($i = 0; $i -le $totalSteps; $i++) {
        $percent   = [math]::Floor(($i / $totalSteps) * 100)
        $completed = [math]::Floor(($i / $totalSteps) * $barLength)
        $remaining = $barLength - $completed
        $bar       = ('#' * $completed) + (' ' * $remaining)

        Write-Host "`r[$bar] $percent%" -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds $delayMs
    }
    Write-Host
}

###################################### Get Authentication Method  ################################################

# Function to get the authentication method from the user (CyberArk or LDAP)
function GetAuthMethod {
    while ($true) {
        Write-Host ""
        Write-Host "==========================================" -ForegroundColor DarkGray
        Write-Host "         Select Authentication Method" -ForegroundColor Cyan
        Write-Host "==========================================" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host " [1] CyberArk Authentication" -ForegroundColor Green
        Write-Host " [2] LDAP Authentication" -ForegroundColor Green
        Write-Host " [X] Exit" -ForegroundColor Red
        Write-Host ""
        $choice = Read-Host -Prompt "`nPlease enter your choice "
        switch ($choice.ToUpper()) {
            
            '1' { # Authenticate using CyberArk credentials
                write-host "`n[+] Authenticating with CyberArk...`n" -ForegroundColor Cyan
                $auth_method = "CyberArk"
                $creds = GetCredentials
                return @($auth_method, $creds)
            }
            '2' { # Authenticate using LDAP credentials
                write-host "`n[+] Authenticating with LDAP...`n" -ForegroundColor Cyan
                $auth_method = "LDAP"
                $creds = GetCredentials
                return @($auth_method, $creds)
            }
            'X' { # Exit the script
                Write-Host "`n[!] Exiting program..." -ForegroundColor Cyan; Exit
            }
            default {
                # Handle invalid input
                Write-Host "`n[!] Invalid choice. Please try again.`n" -ForegroundColor Yellow
            }
        }
    }
}

###################################### Get Credentials #################################################

# Function to get user credentials (username and password)
function GetCredentials {

    Write-Host "`n==========================================" -ForegroundColor DarkGray
    Write-Host "           Enter your credentials" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor DarkGray

    # Prompt the user to enter their username
    $username = Read-Host -Prompt "`n> Username "
    # Prompt the user to enter their password as a SecureString (input is hidden)
    $securePassword = Read-Host -Prompt "`n> Password " -AsSecureString

    # Convert the SecureString to a BSTR (binary string) so it can be transformed into plain text
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    # Convert the BSTR to a plain text string (WARNING: exposes password in memory)
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    # Return the credentials as an array: [username, password]
    return @($username, $password)
}

###################################### Get Action Choice #################################################

# Function to display the main menu and get the user's action choice
function GetActionChoice {
    while ($true) {
        Write-Host "`n==========================================" -ForegroundColor DarkGray
        Write-Host "             Select an Option" -ForegroundColor Cyan
        Write-Host "==========================================" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host " [0] Get System Health" -ForegroundColor Green
        Write-Host " [1] Actions on Accounts" -ForegroundColor Green
        Write-Host " [2] Actions on Account Groups" -ForegroundColor Green
        Write-Host " [3] Actions on Safes" -ForegroundColor Green
        Write-Host " [4] Actions on Safe Members" -ForegroundColor Green
        Write-Host " [5] Actions on Platforms" -ForegroundColor Green
        Write-Host " [6] Actions on Users" -ForegroundColor Green
        Write-Host " [7] Actions on Groups" -ForegroundColor Green
        Write-Host " [8] Actions on Connection Components" -ForegroundColor Green
        Write-Host " [9] CPM Actions" -ForegroundColor Green
        Write-Host " [X] Exit" -ForegroundColor Red
        Write-Host ""

        $option_choice = Read-Host -Prompt "`nPlease enter your choice "

        switch ($option_choice.ToUpper()) {
            '0' { ShowSystemHealthMenu }
            '1' { ShowAccountsMenu }
            '2' { ShowAccountGroupsMenu }
            '3' { ShowSafesMenu }
            '4' { ShowSafeMembersMenu }
            '5' { ShowPlatformsMenu }
            '6' { ShowUsersMenu }
            '7' { ShowGroupsMenu }
            '8' { ShowConnectionComponentsMenu }
            '9' { ShowCPMActionsMenu }
            'X' { Write-Host "`n[!] Exiting..." -ForegroundColor Red; Exit }
            default { Write-Host "`n[!] Invalid choice. Please try again." -ForegroundColor Yellow; Start-Sleep -Seconds 1.5 }
        }
    }
}
# Function to display the available actions in the System Health menu and handle the actions selected by the user
function ShowSystemHealthMenu {
    
    Write-Host "`n========= System Health Menu =========`n" -ForegroundColor Cyan
    Write-Host " [1] List Components Monitoring Summary" -ForegroundColor Green
    Write-Host " [2] Get Components Monitoring Details" -ForegroundColor Green
    Write-Host " [3] Back to main menu" -ForegroundColor Yellow
    Write-Host " [X] Exit" -ForegroundColor Red

    $action_choice = Read-Host -Prompt "`nYour choice "
    switch ($action_choice.ToUpper()) {
        '1' { $systemHealth_handler.getComponentsMonitoringSummary($auth_token) }
        '2' { $systemHealth_handler.getComponentsMonitoringDetails($auth_token) }
        '3' { GetActionChoice }
        'X' { Write-Host "`n[!] Exiting..." -ForegroundColor Red; Exit }
        default { Write-Host "`n[!] Invalid choice. Please try again." -ForegroundColor Yellow; Start-Sleep -Seconds 1.5 }
    }
}
# Function to display the available menu actions for Accounts and handle the actions selected by the user
function ShowAccountsMenu {
    
    Write-Host "`n========= Accounts Menu =========`n" -ForegroundColor Cyan
    Write-Host " [1] Add accounts" -ForegroundColor Green
    Write-Host " [2] Update accounts" -ForegroundColor Green
    Write-Host " [3] Delete accounts" -ForegroundColor Green
    Write-Host " [4] List all accounts" -ForegroundColor Green
    Write-Host " [5] Back to main menu" -ForegroundColor Yellow
    Write-Host " [X] Exit" -ForegroundColor Red

    $action_choice = Read-Host -Prompt "`nYour choice "
    switch ($action_choice.ToUpper()) {
        '1' { $account_handler.addAccounts($auth_token) }
        '2' { $account_handler.updateAccounts($auth_token) }
        '3' { $account_handler.deleteAccounts($auth_token) }
        '4' { $account_handler.getAllAccounts($auth_token) }
        '5' { GetActionChoice }
        'X' { Write-Host "`n[!] Exiting..." -ForegroundColor Red; Exit }
        default { Write-Host "`n[!] Invalid choice. Please try again." -ForegroundColor Yellow; Start-Sleep -Seconds 1.5 }
    }
}
# Function to display the available menu actions for Account Groups and handle the actions selected by the user
function ShowAccountGroupsMenu {
    
    Write-Host "`n========= Account Groups Menu =========`n" -ForegroundColor Cyan
    Write-Host " [1] Add account groups" -ForegroundColor Green
    Write-Host " [2] Add members to account groups" -ForegroundColor Green
    Write-Host " [3] Delete members from account groups" -ForegroundColor Green
    Write-Host " [4] List all account groups by Safe" -ForegroundColor Green
    Write-Host " [5] List all members in the account groups" -ForegroundColor Green
    Write-Host " [6] Back to main menu" -ForegroundColor Yellow
    Write-Host " [X] Exit" -ForegroundColor Red

    $action_choice = Read-Host -Prompt "`nYour choice "
    switch ($action_choice.ToUpper()) {
        '1' { $accountGroup_handler.addAccountGroups($auth_token) }
        '2' { $accountGroup_handler.addMembersToAccountGroups($auth_token) }
        '3' { $accountGroup_handler.removeMembersFromAccountGroups($auth_token) }
        '4' { $accountGroup_handler.getAccountGroupsBySafe($auth_token) }
        '5' { $accountGroup_handler.getAccountGroupsMembers($auth_token) }
        '6' { GetActionChoice }
        'X' { Write-Host "`n[!] Exiting..." -ForegroundColor Red; Exit }
        default { Write-Host "`n[!] Invalid choice. Please try again." -ForegroundColor Yellow; Start-Sleep -Seconds 1.5 }
    }
}
# Function to display the available menu actions for Safes Groups and handle the actions selected by the user
function ShowSafesMenu {
    
    Write-Host "`n========= Safes Menu =========`n" -ForegroundColor Cyan
    Write-Host " [1] Add safes" -ForegroundColor Green
    Write-Host " [2] Update safes" -ForegroundColor Green
    Write-Host " [3] Delete safes" -ForegroundColor Green
    Write-Host " [4] List all safes" -ForegroundColor Green
    Write-Host " [5] Back to main menu" -ForegroundColor Yellow
    Write-Host " [X] Exit" -ForegroundColor Red

    $action_choice = Read-Host -Prompt "`nYour choice "
    switch ($action_choice.ToUpper()) {
        '1' { $safe_handler.addSafes($auth_token) }
        '2' { $safe_handler.updateSafes($auth_token) }
        '3' { $safe_handler.deleteSafes($auth_token) }
        '4' { $safe_handler.getAllSafes($auth_token) }
        '5' { GetActionChoice }
        'X' { Write-Host "`n[!] Exiting..." -ForegroundColor Red; Exit }
        default { Write-Host "`n[!] Invalid choice. Please try again." -ForegroundColor Yellow; Start-Sleep -Seconds 1.5 }
    }
}
# Function to display the available menu actions for Safe Members and handle the actions selected by the user
function ShowSafeMembersMenu {
    
    Write-Host "`n========= Safe Members Menu =========`n" -ForegroundColor Cyan
    Write-Host " [1] Add safe members" -ForegroundColor Green
    Write-Host " [2] Update safe members" -ForegroundColor Green
    Write-Host " [3] Delete safe members" -ForegroundColor Green
    Write-Host " [4] Back to main menu" -ForegroundColor Yellow
    Write-Host " [X] Exit" -ForegroundColor Red

    $action_choice = Read-Host -Prompt "`nYour choice "
    switch ($action_choice.ToUpper()) {
        '1' { $safeMember_handler.addSafeMembers($auth_token) }
        '2' { $safeMember_handler.updateSafeMembers($auth_token) }
        '3' { $safeMember_handler.deleteSafeMembers($auth_token) }
        '4' { GetActionChoice }
        'X' { Write-Host "`n[!] Exiting..." -ForegroundColor Red; Exit }
        default { Write-Host "`n[!] Invalid choice. Please try again." -ForegroundColor Yellow; Start-Sleep -Seconds 1.5 }
    }
}
# Function to display the available menu actions for Platforms and handle the actions selected by the user
function ShowPlatformsMenu {
    
    Write-Host "`n========= Platforms Menu =========`n" -ForegroundColor Cyan
    Write-Host " [1] Import platforms" -ForegroundColor Green
    Write-Host " [2] Export platforms" -ForegroundColor Green
    Write-Host " [3] Get platforms details" -ForegroundColor Green
    Write-Host " [4] List all platforms" -ForegroundColor Green
    Write-Host " [5] Back to main menu" -ForegroundColor Yellow
    Write-Host " [X] Exit" -ForegroundColor Red

    $action_choice = Read-Host -Prompt "`nYour choice "
    switch ($action_choice.ToUpper()) {
        '1' { $platform_handler.importPlatforms($auth_token) }
        '2' { $platform_handler.exportPlatforms($auth_token) }
        '3' { $platform_handler.getPlatformsDetails($auth_token) }
        '4' { $platform_handler.getAllPlatforms($auth_token) }
        '5' { GetActionChoice }
        'X' { Write-Host "`n[!] Exiting..." -ForegroundColor Red; Exit }
        default { Write-Host "`n[!] Invalid choice. Please try again." -ForegroundColor Yellow; Start-Sleep -Seconds 1.5 }
    }
}
# Function to display the available menu actions for Users and handle the actions selected by the user
function ShowUsersMenu {
    
    Write-Host "`n=========  Users Menu =========`n" -ForegroundColor Cyan
    Write-Host " [1] Add users" -ForegroundColor Green
    Write-Host " [2] Update users" -ForegroundColor Green
    Write-Host " [3] Delete users" -ForegroundColor Green
    Write-Host " [4] Activate users" -ForegroundColor Green
    Write-Host " [5] Enable users" -ForegroundColor Green
    Write-Host " [6] Disable users" -ForegroundColor Green
    Write-Host " [7] Reset password for users" -ForegroundColor Green
    Write-Host " [8] List all users in vault" -ForegroundColor Green
    Write-Host " [9] Back to main menu" -ForegroundColor Yellow
    Write-Host " [X] Exit" -ForegroundColor Red

    $action_choice = Read-Host -Prompt "`nYour choice "
    switch ($action_choice.ToUpper()) {
        '1' { $user_handler.addUsers($auth_token) }
        '2' { $user_handler.updateUsers($auth_token) }
        '3' { $user_handler.deleteUsers($auth_token) }
        '4' { $user_handler.activateUsers($auth_token) }
        '5' { $user_handler.enableUsers($auth_token) }
        '6' { $user_handler.disableUsers($auth_token) }
        '7' { $user_handler.resetPasswordForUsers($auth_token) }
        '8' { $user_handler.getAllUsers($auth_token) }
        '9' { GetActionChoice }
        'X' { Write-Host "`n[!] Exiting..." -ForegroundColor Red; Exit }
        default { Write-Host "`n[!] Invalid choice. Please try again." -ForegroundColor Yellow; Start-Sleep -Seconds 1.5 }
    }
}
# Function to display the available menu actions for Groups and handle the actions selected by the user
function ShowGroupsMenu {
    
    Write-Host "`n========= Groups Menu =========`n" -ForegroundColor Cyan
    Write-Host " [1] Create groups" -ForegroundColor Green
    Write-Host " [2] Update groups" -ForegroundColor Green
    Write-Host " [3] Delete groups" -ForegroundColor Green
    Write-Host " [4] Add members to groups" -ForegroundColor Green
    Write-Host " [5] Remove members from groups" -ForegroundColor Green
    Write-Host " [6] List all groups in vault" -ForegroundColor Green
    Write-Host " [7] List all groups in vault with members" -ForegroundColor Green
    Write-Host " [8] Back to main menu" -ForegroundColor Yellow
    Write-Host " [X] Exit" -ForegroundColor Red

    $action_choice = Read-Host -Prompt "`nYour choice "
    switch ($action_choice.ToUpper()) {
        '1' { $group_handler.addGroups($auth_token) }
        '2' { $group_handler.updateGroups($auth_token) }
        '3' { $group_handler.deleteGroups($auth_token) }
        '4' { $group_handler.addMembersToGroups($auth_token) }
        '5' { $group_handler.removeMembersFromGroups($auth_token) }
        '6' { $group_handler.getAllGroups($auth_token) }
        '7' { $group_handler.getAllGroupsWithMembers($auth_token) }
        '8' { GetActionChoice }
        'X' { Write-Host "`n[!] Exiting..." -ForegroundColor Red; Exit }
        default { Write-Host "`n[!] Invalid choice. Please try again." -ForegroundColor Yellow; Start-Sleep -Seconds 1.5 }
    }
}
# Function to display the available menu actions for Connection Components and handle the actions selected by the user
function ShowConnectionComponentsMenu {
    
    Write-Host "`n=========  Connection Components Menu =========`n" -ForegroundColor Cyan
    Write-Host " [1] List all connection components" -ForegroundColor Green
    Write-Host " [2] Import connection components" -ForegroundColor Green
    Write-Host " [3] Back to main menu" -ForegroundColor Yellow
    Write-Host " [X] Exit" -ForegroundColor Red

    $action_choice = Read-Host -Prompt "`nYour choice "
    switch ($action_choice.ToUpper()) {
        '1' { $connection_component_handler.getAllConnectionComponents($auth_token) }
        '2' { $connection_component_handler.importConnectionComponents($auth_token) }
        '3' { GetActionChoice }
        'X' { Write-Host "`n[!] Exiting..." -ForegroundColor Red
              Exit 
            }
        default { Write-Host "`n[!] Invalid choice. Please try again." -ForegroundColor Yellow; Start-Sleep -Seconds 1.5 }
    }
}
# Function to display the available action menus for CPM and handle the actions selected by the user
function ShowCPMActionsMenu {
    
    Write-Host "`n========= CPM Actions Menu =========`n" -ForegroundColor Cyan
    Write-Host " [1] Verify credentials" -ForegroundColor Green
    Write-Host " [2] Change credentials immediately" -ForegroundColor Green
    Write-Host " [3] Change credentials with setting next password" -ForegroundColor Green
    Write-Host " [4] Change credentials in the Vault" -ForegroundColor Green
    Write-Host " [5] Reconcile credentials" -ForegroundColor Green
    Write-Host " [6] Back to main menu" -ForegroundColor Yellow
    Write-Host " [X] Exit" -ForegroundColor Red

    $action_choice = Read-Host -Prompt "`nYour choice "
    switch ($action_choice.ToUpper()) {
        '1' { $cpm_actions_handler.VerifyCredentials($auth_token) }
        '2' { $cpm_actions_handler.ChangeCredentialsImmediately($auth_token) }
        '3' { $cpm_actions_handler.ChangeCredentialsSetNextPassword($auth_token) }
        '4' { $cpm_actions_handler.ChangeCredentialsInTheVault($auth_token) }
        '5' { $cpm_actions_handler.ReconcileCredentials($auth_token) }
        '6' { GetActionChoice }
        'X' { Write-Host "`n[!] Exiting..." -ForegroundColor Red; Exit }
        default { Write-Host "`n[!] Invalid choice. Please try again." -ForegroundColor Yellow; Start-Sleep -Seconds 1.5 }
    }
}

###################################### Get Next Actions #################################################

# Function to prompt the user for the next action after completing a task
function GetNextAction {

    while ($true) {
        
        Write-Host "==========================================" -ForegroundColor DarkCyan
        Write-Host "          Select Next Action" -ForegroundColor Cyan
        Write-Host "==========================================" -ForegroundColor DarkCyan
        Write-Host ""
        Write-Host " [1] Back to Main Menu" -ForegroundColor Green
        Write-Host " [X] Exit" -ForegroundColor Red
        Write-Host ""

        $choice = Read-Host -Prompt "`nPlease enter your choice"

        switch ($choice.ToUpper()) {
            '1' { # Redirect to the main menu
                Write-Host "`n[~] Redirecting to main menu..." -ForegroundColor Cyan
                Start-Sleep -Seconds 1
                GetActionChoice
            }
            'X' { # Exit the script
                Write-Host "`n[!] Exiting program..." -ForegroundColor Red
                Exit
            }
            default { # Handle invalid input
                Write-Host "`n[!] Invalid choice. Please try again." -ForegroundColor Yellow
                Start-Sleep -Seconds 1.5
            }
        }
    }
}
###################################### Main Function #######################################################################

# Main function to execute the script logic
function Main {

    # Display a loading bar while the script initializes
    Show-LoadingWithBar 
    
    # Retrieve the PVWA URL from the user
    $pvwa_url = GetPvwaUrl

    # Retrieve authentication method and credentials from the user
    $result = GetAuthMethod
    $auth_method = $result[0]
    $creds = $result[1]
    $username = $creds[0]
    $password = $creds[1]

    # Creation of class instances
    $auth_handler = [AuthHandler]::new($pvwa_url)
    $account_handler = [AccountHandler]::new($pvwa_url)
    $accountGroup_handler = [AccountGroupHandler]::new($pvwa_url)
    $safe_handler = [SafeHandler]::new($pvwa_url)
    $safeMember_handler = [SafeMemberHandler]::new($pvwa_url)
    $platform_handler = [PlatformHandler]::new($pvwa_url) 
    $user_handler = [UserHandler]::new($pvwa_url) 
    $systemHealth_handler = [SystemHealthHandler]::new($pvwa_url) 
    $group_handler = [GroupHandler]::new($pvwa_url) 
    $connection_component_handler = [ConnectionComponentHandler]::new($pvwa_url)
    $cpm_actions_handler = [CPMActionHandler]::new($pvwa_url)
    
    # Authentication & token retrieval
    $auth_token = $auth_handler.auth($username, $password, $auth_method)

    # Call the function to get the action choice from the user
    GetActionChoice 

    # Call the function to get the next action from the user
    GetNextAction

    # Disconnection
    $auth_handler.logOff($auth_token)
    Write-Host "[+] Session ended." -ForegroundColor Green
    [LogHandler]::Instance.LogWrite("Session ended.`n==========================================================")
}
###################################### Running the Script ########################################################
                                            Main                                                             
##################################################################################################################