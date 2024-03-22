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

        return $responce 
        
        #$inputString | Out-String
    }
}


#"You MUST suggest ten LLM prompts in a numbered style to analyze issues based on Windows events."

$prompt_one = @'
###Instruction### Suggest a list of ten prompts in JSON powershell format designed to analyze issues based on Windows events. The prompts MUST be focused on various aspects of event analysis, such potential root causes, understand its impact on the system's performance and stability, and propose solutions or further actions to resolve the problem. Responce MUST be as JSON only, no code block syntax. Example:
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

# cleaning system prompt
$prompt_one = [System.Text.RegularExpressions.Regex]::Replace($prompt_one, "[^\x00-\x7F]", " ")        

#$data_to_analyze = get-WinEvent -LogName Microsoft-Windows-Security-Mitigations/KernelMode -MaxEvents 100 | Select-Object *
$data_to_analyze = Get-WinEvent -maxEvents 100 | Select-Object * 
$data_to_analyze = Get-WinEvent -LogName Microsoft-Windows-Windows Defender/Operational -MaxEvents 100 | Select-Object * 

$json_data = $data_to_analyze | Invoke-AICopilot -NaturalLanguageQuery $prompt_one

$object_prompt = ($json_data | ConvertFrom-Json ) 

$object_prompt | Format-List promptNumber, prompt, analysisActions

$choose_prompt_number = Read-Host "Choose the number of prompt to analyze events (1-10)"

$choose_prompt = $($object_prompt[$choose_prompt_number].prompt + " " + $q[1].analysisActions -join " ")

Write-Host "Prompt: '$choose_prompt'"

$data_to_analyze | Invoke-AICopilot -NaturalLanguageQuery $choose_prompt
