# Disable certificate checking to allow HTTPS requests to servers with self-signed or invalid certificates ###
# useful in test environments; not recommended in production #################################################
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
##############################################################################################################

# Define a singleton class to handle logging and error output
class LogHandler {

    # Static property to hold the singleton instance
    static [LogHandler] $Instance 

    # Properties to hold log file names and directory
    [string] $LogFile # Path to the success log file
    [string] $ErrorFile # Path to the error log file
    [string] $LogDirectory # Path to the directory where logs will be stored

    # Static constructor (runs once when the class is first used)
    static LogHandler() {
        # Create a single instance and assign it to the static property
        [LogHandler]::Instance = [LogHandler]::new()
    }

###################################### Create Log folder & Files ##############################################
    
# Constructor - initializes file paths and creates the log directory/files
    LogHandler() {
        try {
            # Log & Error filenames
            $this.LogFile = "log.log"
            $this.ErrorFile = "error.log"

            # Get the current working directory
            $currentDir = Get-Location
            # Get its parent directory
            $parentDir = Split-Path -Path $currentDir -Parent
            # Build the full path to the Log folder
            $this.LogDirectory = Join-Path -Path $parentDir -ChildPath "Log"

            # Create the Log directory if it doesn't already exist
            if (-not (Test-Path $this.LogDirectory)) {
                New-Item -Path $this.LogDirectory -ItemType Directory -Force | Out-Null
            }

            # Create log files if they don't exist
            $this.createLogFiles()
        }
        catch {
            # Print error to console if something fails during initialization
            Write-Host "Error in LogHandler constructor : $_" -ForegroundColor Red
            throw $_
        }
    }

###################################### Create the Log Files ######################################################

# Create the log and error files if they do not already exist
    [void] createLogFiles() {
        # Full path to log file
        $logPath = Join-Path $this.LogDirectory $this.LogFile
        # Full path to error file
        $errorPath = Join-Path $this.LogDirectory $this.ErrorFile

        # Create the log file if missing
        if (-not (Test-Path $logPath)) {
            New-Item -Path $logPath -ItemType File | Out-Null
        }
        # Create the error file if missing
        if (-not (Test-Path $errorPath)) {
            New-Item -Path $errorPath -ItemType File | Out-Null
        }
    }

###################################### Get Current DateTime ####################################################

# Return the current date and time formatted for logging    
    [string] LogDate() {
        return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

###################################### Write Logs (success) ####################################################

# Write a success/info message to the log file with timestamp
    [void] LogWrite([string]$Message) {
        $line = "$($this.LogDate())`t$Message"
        Add-Content -Path (Join-Path $this.LogDirectory $this.LogFile) -Value $line
    }

###################################### Write Logs (failure) ####################################################  

# Write an error message to the error file with timestamp
    [void] ErrorWrite([string]$Message) {
        $line = "$($this.LogDate())`t$Message"
        Add-Content -Path (Join-Path $this.LogDirectory $this.ErrorFile) -Value $line
    }
}
