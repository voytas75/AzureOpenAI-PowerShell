# Define the AI_LLM function
function Invoke-AICopilot_old1 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true, Position = 0)]
        [string]$NaturalLanguageQuery
    )
    . $PSScriptRoot\Invoke-AzureOpenAIChatCompletion.ps1 
    # Convert the input object to a string
    $inputString = $InputObject | Out-String

    # Log the input object and natural language query
    LogData -InputString $inputString -NaturalLanguageQuery $NaturalLanguageQuery

    Write-Verbose ($inputString)
    # Call a function to interpret the input using a language model and the user's query
    Invoke-AzureOpenAIChatCompletion -SystemPrompt $NaturalLanguageQuery -OneTimeUserPrompt $inputString -Precise -simpleresponse

}

# Define the LogData function
function LogData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputString,

        [Parameter(Mandatory = $true)]
        [string]$NaturalLanguageQuery
    )

    # Log the input string and natural language query to a file or other logging mechanism
    # Example: Write-Output "$InputString | $NaturalLanguageQuery" >> log.txt
}

# Define the InterpretUsingLLM function
function InterpretUsingLLM {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputString,

        [Parameter(Mandatory = $true)]
        [string]$NaturalLanguageQuery
    )

    # Send the input string and the natural language query to the language model for interpretation
    # Receive interpreted response
    # Return interpreted response
}

# Define the ExecuteCommand function
function ExecuteCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    # Execute the command
    # Return result
}

# Call the cmdlet you want to pipe to AI_LLM
#Get-Process | Invoke-AICopilot -NaturalLanguageQuery "Show only processes using more than 500MB of memory"

function Invoke-AICopilot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true, Position = 0)]
        [string]$NaturalLanguageQuery
    )

    begin {
        . $PSScriptRoot\Invoke-AzureOpenAIChatCompletion.ps1 

        # This block runs once before any input is processed
        $inputObjects = @()
    }

    process {
        # This block runs once for each item of input
        $inputObjects += $InputObject
    }

    end {
        # This block runs once after all input has been processed
        # Concatenate all process names into a single string
        $inputString = $inputObjects | Out-String

        #$MyInvocation | ConvertTo-Json
        
        # Rest of your code...
        $responce = Invoke-AzureOpenAIChatCompletion -SystemPrompt $NaturalLanguageQuery -OneTimeUserPrompt $inputString -Precise -simpleresponse

        Write-Host "start"
        $responce  | ConvertFrom-Json
        Write-Host "stop"
        #$inputString | Out-String
    }
}


#"You MUST suggest ten LLM prompts in a numbered style to analyze issues based on Windows events."

$prompt_one = @'
###Instruction### Produce a list of ten prompts in powershell JSON format designed to analyze issues based on Windows events. The prompts should be numbered and focus on various aspects of event analysis, such potential root causes, understand its impact on the system's performance and stability, and propose solutions or further actions to resolve the problem. Responce MUSt have JSON only, no code block syntax. Example:
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
    "promptNumber": 2,
    "prompt": "Determine if the system time change by W32time service is expected behavior and if it aligns with the configured time synchronization settings.",
    "eventType": "W32time Service Event",
    "eventID": 261,
    "eventLevel": "Information",
    "eventMessage": "W32time service has set the system time",
    "eventTime": "2024-03-22T19:02:09.603Z",
    "previousTime": "2024-03-22T19:02:09.602Z",
    "analysisActions": [
      "Check time synchronization settings.",
      "Ensure the time source is reliable and accessible.",
      "Review if there are any network connectivity issues."
    ]
  }
]
'@

#>


Get-WinEvent -maxEvents 10 | select * | Invoke-AICopilot2 -NaturalLanguageQuery $prompt_one