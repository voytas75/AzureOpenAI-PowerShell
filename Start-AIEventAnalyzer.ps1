<#
.SYNOPSIS
This function logs the input string and natural language query.

.DESCRIPTION
The LogData function takes an input string and a natural language query as parameters. 
It logs these parameters to a file or other logging mechanism. 

.PARAMETER InputString
This parameter accepts the input string that needs to be logged.

.PARAMETER NaturalLanguageQuery
This parameter accepts the natural language query that needs to be logged.

.EXAMPLE
LogData -InputString $inputString -NaturalLanguageQuery "Show only processes using more than 500MB of memory"
#>
function LogData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputString,

        [Parameter(Mandatory = $true)]
        [string]$NaturalLanguageQuery
    )

    # Log the input string and natural language query to a file or other logging mechanism
    # This could be a file, a database, a logging service, etc.
    # Example: Write-Output "$InputString | $NaturalLanguageQuery" >> log.txt
}

<#
.SYNOPSIS
This function uses Azure OpenAI to interpret the input using a language model and the user's query.

.DESCRIPTION
The Invoke-AICopilot function takes an input object and a natural language query as parameters. 
It converts the input object to a string and calls the Invoke-AzureOpenAIChatCompletion function to interpret the input using a language model and the user's query.

.PARAMETER InputObject
This parameter accepts the input object that needs to be interpreted.

.PARAMETER NaturalLanguageQuery
This parameter accepts the natural language query to interpret the input object.

.EXAMPLE
Invoke-AICopilot -InputObject $InputObject -NaturalLanguageQuery "Show only processes using more than 500MB of memory"
#>
function Invoke-AIEventAnalyzer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true, Position = 0)]
        [string]$NaturalLanguageQuery
    )

    begin {
        # Load the Invoke-AzureOpenAIChatCompletion script
        . $PSScriptRoot\Invoke-AzureOpenAIChatCompletion.ps1 

        # This block runs once before any input is processed
        # Initialize an array to store the input objects
        $inputObjects = @()
    }

    process {
        # This block runs once for each item of input
        # Add the current input object to the array
        $inputObjects += $InputObject
    }

    end {
        # This block runs once after all input has been processed
        # Convert the array of input objects into a single string
        $inputString = $inputObjects | Out-String

        # Call the Invoke-AzureOpenAIChatCompletion function to interpret the input using a language model and the user's query
        $response = Invoke-AzureOpenAIChatCompletion -SystemPrompt $NaturalLanguageQuery -OneTimeUserPrompt $inputString -Precise -simpleresponse

        # Return the response from the Azure OpenAI Chat Completion function
        return $response 
    }
}

<#
.SYNOPSIS
This function clears the LLMDataJSON.

.DESCRIPTION
The Clear-LLMDataJSON function takes a string of data as input, finds the first instance of '[' and the last instance of ']', and returns the substring between these two characters. This effectively removes any characters before the first '[' and after the last ']'.

.PARAMETER data
A string of data that needs to be cleared.

.EXAMPLE
$data = "{extra characters}[actual data]{extra characters}"
Clear-LLMDataJSON -data $data
#>
# This function is used to clear the LLMDataJSON
function Clear-LLMDataJSON {
    # Define the parameters for the function
    param (
        # The data parameter is mandatory and should be a string
        [Parameter(Mandatory = $true)]
        [string]$data
    )
    # Find the first occurrence of '[' and remove everything before it
    $data = $data.Substring($data.IndexOf('['))
    # Find the last occurrence of ']' and remove everything after it
    $data = $data.Substring(0, $data.LastIndexOf(']') + 1)
    # Return the cleaned data
    return $data
}

function Get-EventSeverity {
    # Define the parameters for the function
    param (
        # The Severity parameter is mandatory and should be an integer or a string
        [Parameter(Mandatory = $true)]
        [ValidateScript({
                if (($_ -is [int] -and 1..5 -contains $_) -or ($_ -is [string] -and $_ -in "Critical", "Error", "Warning", "Information", "Verbose")) {
                    $true
                }
                else {
                    throw "Invalid input. Please enter an integer between 1 and 5 or a valid severity name."
                }
            })]
        $Severity
    )

    # Define the hash table for severity levels and their corresponding names
    $EventLevels = @{
        1 = "Critical"
        2 = "Error"
        3 = "Warning"
        4 = "Information"
        5 = "Verbose"
    }

    # Define the reverse hash table for severity names and their corresponding levels
    $EventLevelsReverse = $EventLevels.GetEnumerator() | Group-Object -Property Value -AsHashTable -AsString

    # Check if the input is an integer or a string and return the corresponding value
    if ($Severity -is [int]) {
        return $EventLevels[$Severity]
    }
    else {
        return ($EventLevelsReverse[$Severity]).Name
    }
}

function Start-AIEventAnalyzer {
    [CmdletBinding()]
    param (
        
    )

    # Define the prompt for the AI model
    $prompt_one = @'
###Instruction### 

You act as data analyst. Your task is to suggest a list of prompts designed to analyze issues based on the provided data. The prompts MUST be focused on potential root causes, understand its impact on the system's performance and stability, and propose detailed step-by-step solutions or further actions to resolve the problem. Responce MUST be as JSON format only. Audience is IT Proffesional. 

Example of JSON with two records:
[
  {
    "promptNumber": 1,
    "prompt": "Analyze the root cause of the W32time service stopping and assess if it is a regular behavior or an indication of an underlying issue.",
    "eventType": "W32time Service Event",
    "eventID": 258,
    "eventLevel": "Information",
    "eventMessage": "W32time service is stopping",
    "eventTime": "2024-03-22T19:02:09.605Z",
    "eventReturnCode": "0x00000000",
    "analysisActions": [
      "Check if the service is configured to stop at scheduled times.",
      "Review system logs for any related errors or warnings.",
      "Verify if there was a system shutdown or restart."
    ]
  },
  {
    "promptNumber": 3,
    "prompt": "Examine the security implications of Acrobat's AcroCEF.exe being blocked from making system calls to Win32k.sys and suggest measures to mitigate potential risks.",
    "eventType": "Security Mitigation",
    "eventID": 10,
    "eventLevel": "Warning",
    "eventMessage": "The process AcroCEF.exe was prevented from making system calls to the Win32k.sys library.",
    "eventTime": "2024-03-16T22:26:05Z",
    "eventProcessID": 22432,
    "analysisActions": [
      "Ensure that Adobe Acrobat is running the latest version.",
      "Review Adobe Acrobat's security settings and permissions.",
      "Check for any related security advisories from Adobe."
    ]
  }
]
'@

    # Clean the system prompt by removing non-ASCII characters
    $prompt_one = [System.Text.RegularExpressions.Regex]::Replace($prompt_one, "[^\x00-\x7F]", " ")        

    # Get a list of all Windows event logs, sort them by record count in descending order, and select the top 25 logs
    $logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Sort-Object RecordCount -Descending | Select-Object LogName, RecordCount

    # Display the name and record count of each log
    #$logs | ForEach-Object {Write-Host "$($_.LogName) - $($_.RecordCount) records"}
    try {
        $logs.where{ $_.RecordCount -gt 0 }  | Out-Host -Paging
    }
    catch [System.Management.Automation.HaltCommandException] {
        # Handle termination here (e.g., write message)
        Write-Host "Command stopped by user (Quit)"
    }

    # Ask the user to input the name of the log they want to analyze
    $chosenLogName = Read-Host "Please enter the LogName from the list above to analyze events (default: $($logs[0].LogName))"


    # Check if the chosen log name is empty or null. If it is, set it to the first log name in the logs list
    if ([string]::IsNullOrEmpty($chosenLogName)) {
        $chosenLogName = $logs[0].LogName
    }

    # Get the record count for the chosen log name
    $logRecordCount = ($logs | Where-Object { $_.logname -eq "$chosenLogName" }).Recordcount
    # Display the record count for the chosen log name
    Write-Host "The log '$chosenLogName' has $logRecordCount events of all severity levels."

    # Loop until a valid severity level is entered
    do {
        # Ask the user to enter the severity level
        Write-Host "Please enter the severity level of the events you want to analyze. Options are: Critical, Error, Warning, Information, Verbose, or All."
        $chosenSeverityLevel = Read-Host "Enter the severity level (default: All)"
        # If the entered severity level is valid, get the events for that severity level
        if ($chosenSeverityLevel -in @("Critical", "Error", "Warning", "Information", "Verbose")) {
            $filterXPath = "*[System[(Level=$(Get-EventSeverity -Severity $chosenSeverityLevel))]]"
            $data_to_analyze = Get-WinEvent -LogName $chosenLogName -FilterXPath $filterXPath -ErrorAction SilentlyContinue | Select-Object Message, Level, ProviderName, ProviderId, LogName, TimeCreated 
            $logRecordServerityCount = $data_to_analyze.Count
        }
        # If the entered severity level is empty or null, set it to "All" and get all events
        elseif ([string]::IsNullOrEmpty($chosenSeverityLevel)) {
            $chosenSeverityLevel = "All"
            $logRecordServerityCount = $logRecordCount
        }
        # If the entered severity level is invalid, set it to "All" and get all events
        else {
            $chosenSeverityLevel = "All"
            $logRecordServerityCount = $logRecordCount
        }
    } until ([int]$logRecordServerityCount -gt 0)

    # Ask the user to enter the number of most recent events they want to analyze
    $chosenLogNameNewest = Read-Host "Please enter the number of most recent '$chosenLogName' for '$chosenSeverityLevel' serverity events you want to analyze (1-$logRecordServerityCount) (default: 10)"
    # If the entered number is empty or null, set it to 10
    if ([string]::IsNullOrEmpty($chosenLogNameNewest)) {
        $chosenLogNameNewest = 10
    }
    # If the chosen severity level is not valid, get the most recent events up to the entered number
    if ($chosenSeverityLevel -notin @("Critical", "Error", "Warning", "Information", "Verbose")) {
        $data_to_analyze = Get-WinEvent -LogName $chosenLogName -MaxEvents $chosenLogNameNewest | Select-Object Message, Level, ProviderName, ProviderId, LogName, TimeCreated 
    }
    else {
        $data_to_analyze = $data_to_analyze | Select-Object -First $chosenLogNameNewest
    }
    $logRecordServerityCount = $data_to_analyze.Count

    # Display the chosen log name, severity level, and event count
    Write-Host "LogName: $chosenLogName"
    Write-Host "Level: $chosenSeverityLevel"
    Write-Host "Event count: $logRecordServerityCount"

    # Invoke the AI model with the prompt and the data to analyze
    $json_data = $data_to_analyze | Invoke-AIEventAnalyzer -NaturalLanguageQuery $prompt_one

    # Clean the returned JSON data
    $json_data = Clear-LLMDataJSON -data $json_data

    # Convert the cleaned JSON data to a PowerShell object
    $object_prompt = ($json_data | ConvertFrom-Json ) 

    # Loop until the user chooses to quit
    while ($true) {
        # Display the prompt number and prompt
    ($object_prompt | Format-List promptNumber, prompt) | Out-Host -Paging
        # Inform the user that they can quit the script at any time
        Write-Host "Enter 'Q' and ENTER to quit the script at any time."

        # Ask the user to choose a prompt number to analyze events
        $prompt_count = $object_prompt.Count
        $choose_prompt_number = Read-Host "Choose the number of prompt to analyze events (1-$prompt_count)"

        # If the user chooses to quit, end the script
        if ($choose_prompt_number -eq 'q' -or $choose_prompt_number -eq 'Q') {
            Write-Host "Ending script..."
            break
        }

        # Construct the chosen prompt
        $choose_prompt = $($object_prompt[($choose_prompt_number - 1)].prompt)

        # Display the chosen prompt
        Write-Host "Prompt: '$choose_prompt'"

        # Invoke the AI model with the chosen prompt and the data to analyze
    ($data_to_analyze | Invoke-AIEventAnalyzer -NaturalLanguageQuery $choose_prompt) | Out-Host -Paging

        # Ask the user to press any key to continue
        Write-Host "Press any key to continue ..."
        $null = [Console]::ReadKey($true)
    }
}