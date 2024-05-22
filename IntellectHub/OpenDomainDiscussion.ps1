[CmdletBinding()]
param(
    [string] $Topic = "The Impact of GPT on IT Microsoft Administrators",
    [int] $Rounds = 2,
    [int] $expertCount = 2 
)

# Define Language Model class
class LanguageModel {
    [string] $name
    [string[]] $memory
    [string] $supplementary_information

    LanguageModel([string] $name, [string] $supplement) {
        $this.name = $name
        $this.memory = @()
        $this.supplementary_information = $supplement
    }

    [string] InvokeLLM([string] $prompt) {
        try {
            # Simulate language model response
            $prompt = $prompt + "`n`n" + $this.supplementary_information
            write-host $prompt -ForegroundColor DarkYellow
            $arguments = @($prompt, 1000, "Precise", $this.name, "udtgpt35turbo", $true)
            $response = Invoke-PSAOAICompletion @arguments
            $this.memory += $response
            #return "This is $($this.name)'s response to:`n$($prompt)`n '$response'"
            return "This is $($this.name)'s response:`n===`n$($response.trim())`n==="
        }
        catch {
            return "An error occurred while invoking the language model: $_"
        }
    }

    [string[]] GetLastNMemoryElements([int] $n) {
        # Get the last N elements from the memory
        $lastNElements = ($this.memory | Select-Object -Last $n)
        #Write-Host "$n last $($this.name) memories:" -ForegroundColor Yellow
        return $lastNElements
    }
}

# Create a moderator language model

$noteModerator = @"
NOTE: You are Moderator. Keep focus on the prompt. Summarize key points, identify areas of agreement/disagreement, and prompt further exploration. Maintain a neutral stance and encourage respectful exchange of ideas. Identify the main themes or subjects discussed in the Topic. Display any response as JSON object with keys you choose. Show only JSON. Example: 
``````json
{
    "Topic": "",
    "themes_and_subjects": [
        ""
    ],
    "key_points": [
        ""
    ],
    "areas_of_agreement": [
        ""
    ],
    "areas_of_disagreement": [
        ""
    ],
    "further_exploration": [
        ""
    ],
    "questions_for_experts": [
        ""
        ],
    "other": [
        ""
    ]
}
``````
"@
$moderator = [LanguageModel]::new("Moderator", $noteModerator)

# Define a function to conduct the discussion
function Conduct-Discussion {
    param (
        [string] $topic,
        [int] $rounds,
        [int] $expertCount
    )

    # Create expert language models
    $experts = @()
    for ($i = 1; $i -le $expertCount; $i++) {
        switch ($i) {
            1 {
                $name = "Domain Expert"; $supplement = @"


NOTE: You are $name. Provide a scientifically accurate foundation. Prioritize factual accuracy. Display any response as JSON object with keys you choose. Show only JSON. Example: 
``````json
{
    "Topic": "",
    "Thoughts": [
        ""
    ],
    "Other": [
        ""
    ]
}
``````
"@ 
            }
            2 {
                $name = "Data Analyst"; $supplement = @"


NOTE: You are $name. Analyze and offer insights to unlock the power of data and help make better choices. Use main answer structure. Display any response as JSON object with keys you choose. Show only JSON. Example: 
``````json
{
    "Topic": "",
    "Thoughts": [
        ""
    ],
    "Other": [
        ""
    ]
}
``````
"@ 
            }
            3 {
                $name = "Creative Thinker"; $supplement = @"
            
            
NOTE: You are $name. Unleash your imagination. Explore unconventional ideas and world-building elements. Infuse originality and wonder. Don't be afraid to push boundaries. Display any response as JSON object with keys you choose. Show only JSON. Example: 
``````json
{
    "Topic": "",
    "Thoughts": [
        ""
    ],
    "Other": [
        ""
    ]
}
``````
"@ 
            }
            Default {}
        }
        $expert = [LanguageModel]::new($name, $supplement)
        $experts += $expert
    }

    # Start discussion rounds
    for ($round = 1; $round -le $rounds; $round++) {
        Write-Host "Round $round" -BackgroundColor DarkGreen

        # Moderator asks question
        $questionInstruction = @"
### Instruction ###
You need to analyze the topic and memory, if any, and answer the question. Response as JSON object only.
"@
        $questionmiddle = @"


Topic: $topic

Response JSON object example:
``````json
{
    "Topic": "",
    "Thoughts": [
        ""
    ],
    "Other": [
        ""
    ]
}
``````
"@

        $questionFooter = @"


### Question ###
What are your thoughts on the topic and show them as JSON?
"@


        $moderatorResponse = $moderator.InvokeLLM("Discuss about '$topic'")
        Write-Host "Moderator: $moderatorResponse" -ForegroundColor Green
        #$moderatorResponse = Extract-JSON $moderatorResponse
        $moderatorResponse = Clear-LLMDataJSON $moderatorResponse

        # Each expert responds
        foreach ($expert in $experts) {
            $lastMemoryElement = $expert.GetLastNMemoryElements(1)
            if ($lastMemoryElement) {
                $lastMemoryElement = @"


Memory:
$($lastMemoryElement.trim())
"@
            }

            $questionWithmemory += $questionInstruction
            $questionWithmemory += $questionmiddle
            $questionWithmemory += $lastMemoryElement
            $questionWithmemory += $questionFooter
            $expertResponse = $expert.InvokeLLM($questionWithmemory)
            Write-Host "$($expert.name): $expertResponse" 
            #$expertResponse = Extract-JSON $expertResponse | ConvertFrom-Json
            $expertResponse = Clear-LLMDataJSON $expertResponse | ConvertFrom-Json
            
            $lastMemoryElement = ""
            $questionWithmemory = ""
        }
    }

    # Print experts' memories
    foreach ($expert in $experts) {
        #Write-Host "$($expert.name)'s Memory:" -ForegroundColor Blue
        #Write-Host ($expert.memory) -ForegroundColor Blue
        #Write-Host ""
        $Summarize = @"
Considering the following responses, create a new response that combines the most relevant and interesting information.
$($expert.memory)
"@
        Write-Host "$($expert.name)'s summarized memory:" -BackgroundColor Blue
        #write-Host ($moderator.InvokeLLM($Summarize)) -BackgroundColor Blue
        write-Host ($expert.InvokeLLM($Summarize)) -BackgroundColor Blue
    }

    # General summarization
    foreach ($expert in $experts) {
        $generalMemory += $expert.GetLastNMemoryElements(1)
    }
    $Summarize = @"
Summarize the key points from the provided summaries to create a comprehensive response. Prioritize information directly relevant to the user's Topic.

User's topic: $topic

Summaries:
$generalMemory
"@

    $NewSupplement = @"


Display any response as JSON object with keys you choose. Show only JSON. Example: 
``````json
{
    "Topic": "",
    "Key_points": [
        ""
    ]
}
``````
"@
    $moderator.supplementary_information = $NewSupplement
    $FinalResponse = $moderator.InvokeLLM($Summarize)
    write-Host ($FinalResponse) -BackgroundColor Green
    $FinalResponseObj = Clear-LLMDataJSON $FinalResponse | ConvertFrom-Json
    Write-Host "Topic: $($FinalResponseObj.Topic)"
    Write-Host "Thoughts:"
    foreach ($thought in $FinalResponseObj.Thoughts) {
        Write-Host " - $thought"
    }
    Write-Host "Other:"
    foreach ($other in $FinalResponseObj.Other) {
        Write-Host " - $other"
    }
    Write-Host "Combined:"
    foreach ($Combined in $FinalResponseObj.Combined) {
        Write-Host " - $Combined"
    }
    Write-Host "Key_points:"
    foreach ($Key_points in $FinalResponseObj.Key_points) {
        Write-Host " - $Key_points"
    }
    
    # Provide a general response related to the user's topic
    $generalResponse = "In conclusion, regarding the topic '$topic', the experts have provided valuable insights."
    Write-Host $generalResponse

    #$moderator.GetLastNMemoryElements(1)
    #$moderator.GetLastNMemoryElements(2)
    #$moderator.GetLastNMemoryElements(3)
}

# Import modules and scripts
[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "0", "User")
#Import-Module -Name PSaoAI
Import-module "D:\dane\voytas\Dokumenty\visual_studio_code\github\AzureOpenAI-PowerShell\PSAOAI\PSAOAI.psd1" -Force 
import-module PSWriteColor

$IHGUID = [System.Guid]::NewGuid().ToString()

#region Importing Modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$helperFunctionsPath = Join-Path -Path $scriptPath -ChildPath "helper_functions.ps1"
Try {
    . $helperFunctionsPath
    PSWriteColor\Write-Color -Text "Imported helper function file" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
}
Catch {
    Write-Error -Message "Failed to import helper function file"
    return $false
}
#endregion Importing Modules

#region Creating Team Discussion Folder
Try {
    # Get the current date and time
    $currentDateTime = Get-Date -Format "yyyyMMdd_HHmmss"
    # Create a folder with the current date and time as the name in the example path
    $script:TeamDiscussionDataFolder = Create-FolderInGivenPath -FolderPath $(Create-FolderInUserDocuments -FolderName "OpenDomainDiscussion") -FolderName $currentDateTime
    if ($script:TeamDiscussionDataFolder) {
        PSWriteColor\Write-Color -Text "Team discussion folder was created '$script:TeamDiscussionDataFolder'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Warning -Message "Failed to create discussion folder"
    return $false
}
#endregion Creating Team Discussion Folder


# Conduct the discussion with 3 rounds and 5 experts
Conduct-Discussion -topic $topic -rounds $Rounds -expertCount $expertCount
