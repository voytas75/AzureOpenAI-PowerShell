function Write-LogMessage {
    <#
.SYNOPSIS
This function writes a log message to a specified log file.

.DESCRIPTION
The Write-LogMessage function takes in a message, a log file path, and an optional log level (default is "INFO"). 
It then writes the message to the log file with a timestamp and the specified log level.

.PARAMETER Message
The message to be logged. This parameter is mandatory.

.PARAMETER LogFile
The path of the log file where the message will be written. This parameter is mandatory.

.PARAMETER Level
The level of the log message (e.g., "INFO", "VERBOSE", "ERROR"). This parameter is optional and defaults to "INFO".

.EXAMPLE
Write-LogMessage -Message "System prompt:`n$system_message" -LogFile $logfile -Level "VERBOSE"
#>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $true)]
        [string]$LogFile,
        [Parameter(Mandatory = $false)]
        [string]$Level = "INFO"
    )
    # Get the current date and time in the format "yyyy-MM-dd HH:mm:ss"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Format the log entry
    $logEntry = "[$timestamp [$Level]] $Message"

    # Write the log entry to the log file
    Add-Content -Path $LogFile -Value $logEntry -Force
}