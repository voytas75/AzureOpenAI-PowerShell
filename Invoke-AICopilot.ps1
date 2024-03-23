# Define the AI_LLM function
<#
.SYNOPSIS
This function uses Azure OpenAI to interpret the input using a language model and the user's query.

.DESCRIPTION
The Invoke-AICopilot_old1 function takes an input object and a natural language query as parameters. 
It converts the input object to a string and logs the input object and natural language query. 
Then it calls the Invoke-AzureOpenAIChatCompletion function to interpret the input using a language model and the user's query.

.PARAMETER InputObject
This parameter accepts the input object that needs to be interpreted.

.PARAMETER NaturalLanguageQuery
This parameter accepts the natural language query to interpret the input object.

.EXAMPLE
Invoke-AICopilot_old1 -InputObject $InputObject -NaturalLanguageQuery "Show only processes using more than 500MB of memory"
#>
function Invoke-AICopilot_old1 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true, Position = 0)]
        [string]$NaturalLanguageQuery
    )
    # Load the Invoke-AzureOpenAIChatCompletion script
    . $PSScriptRoot\Invoke-AzureOpenAIChatCompletion.ps1 

    # Convert the input object to a string
    $inputString = $InputObject | Out-String

    # Log the input object and natural language query
    LogData -InputString $inputString -NaturalLanguageQuery $NaturalLanguageQuery

    # Write the input string to the verbose output stream
    Write-Verbose ($inputString)

    # Call the Invoke-AzureOpenAIChatCompletion function to interpret the input using a language model and the user's query
    Invoke-AzureOpenAIChatCompletion -SystemPrompt $NaturalLanguageQuery -OneTimeUserPrompt $inputString -Precise -simpleresponse
}
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
function Invoke-AICopilot {
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
        [Parameter(Mandatory=$true)]
        [string]$data
    )
    # Find the first occurrence of '[' and remove everything before it
    $data = $data.Substring($data.IndexOf('['))
    # Find the last occurrence of ']' and remove everything after it
    $data = $data.Substring(0, $data.LastIndexOf(']') + 1)
    # Return the cleaned data
    return $data
}

# Define the prompt for the AI model
$prompt_one = @'
###Instruction### Suggest a list of two prompts in JSON powershell format designed to analyze issues based on Windows events. The prompts MUST be focused on various aspects of event analysis, such potential root causes, understand its impact on the system's performance and stability, and propose solutions or further actions to resolve the problem. Responce MUST be as JSON only, no code block syntax. Example:
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

# Fetch the Windows events to analyze
$data_to_analyze = Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 10 | Select-Object Message, Level, ProviderName, ProviderId, LogName, TimeCreated 

# Invoke the AI model with the prompt and the data to analyze
$json_data = $data_to_analyze | Invoke-AICopilot -NaturalLanguageQuery $prompt_one

# Clean the returned JSON data
$json_data = Clear-LLMDataJSON -data $json_data

# Convert the cleaned JSON data to a PowerShell object
$object_prompt = ($json_data | ConvertFrom-Json ) 

# Display the prompt number, prompt, and analysis actions from the object
$object_prompt | Format-List promptNumber, prompt, analysisActions

# Ask the user to choose a prompt number to analyze events
$prompt_count = $object_prompt.Count
$choose_prompt_number = Read-Host "Choose the number of prompt to analyze events (1-$prompt_count)"

# Construct the chosen prompt
$choose_prompt = $($object_prompt[$choose_prompt_number].prompt + " " + $object_prompt[$choose_prompt_number].analysisActions -join " ")

# Display the chosen prompt
Write-Host "Prompt: '$choose_prompt'"

# Invoke the AI model with the chosen prompt and the data to analyze
$data_to_analyze | Invoke-AICopilot -NaturalLanguageQuery $choose_prompt
