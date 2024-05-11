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
        # Simulate language model response
        $prompt += "`n"
        $prompt += $this.supplementary_information
        #Write-Host $prompt -BackgroundColor Gray -ForegroundColor White
        $arguments = @($prompt, 1000, "Precise", $this.name, "udtgpt35turbo", $true)
        $response = Invoke-PSAOAICompletion @arguments
        $this.memory += $response
        #return "This is $($this.name)'s response to:`n$($prompt)`n '$response'"
        return "This is $($this.name)'s response:`n===`n$($response.trim())`n==="
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
NOTE: You are Moderator. Facilitate discussion, ensure all experts contribute, and keep focus on the prompt. Summarize key points, identify areas of agreement/disagreement, and prompt further exploration. Maintain a neutral stance and encourage respectful exchange of ideas. Display any response as JSON object with keys you choose. Show only JSON. Example: 
```json
{
    "prompt": "The Impact of GPT on IT Microsoft Administrators",
    "key_points": [
        "GPT (Group Policy Tools) is a powerful tool for managing and configuring Microsoft systems",
        "It has greatly simplified the process of managing multiple systems and enforcing policies",
        "GPT has also increased efficiency and reduced the workload for IT Microsoft Administrators",
        "However, some experts argue that GPT has also made it easier for inexperienced administrators to make mistakes",
        "There is also a concern that GPT may limit the flexibility and customization options for administrators",
        "Overall, the impact of GPT on IT Microsoft Administrators has been largely positive, but there are also some potential drawbacks"
    ],
    "areas_of_agreement": [
        "GPT has made managing and configuring Microsoft systems easier and more efficient",
        "It has reduced the workload for IT Microsoft Administrators",
        "The impact of GPT has been mostly positive"
    ],
    "areas_of_disagreement": [
        "Some experts believe that GPT may limit flexibility and customization options for administrators",
        "There is a concern that inexperienced administrators may make mistakes with GPT"
    ],
    "further_exploration": "How can IT Microsoft Administrators balance the benefits of GPT with the potential drawbacks? Are there any strategies or best practices for using GPT effectively?",
    "other": [
        ""
    ]
}
```
"@
$moderator = [LanguageModel]::new("Moderator",$noteModerator)

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
            1 { $name = "Domain Expert"; $supplement = "NOTE: You are $name. Provide a scientifically accurate foundation. Remember: Prioritize factual accuracy." }
            2 { $name = "Data Analyst"; $supplement = "NOTE: You are $name. Focus: Analyze for themes, conflicts, and engagement. Goal: Offer insights on narrative structure. Remember: Leverage data analysis skills to improve the topic." }
            3 { $name = "Creative Thinker"; $supplement = "NOTE: You are $name. Focus: Unleash your imagination! Explore unconventional ideas and world-building elements. Goal: Infuse originality and wonder. Remember: Don't be afraid to push boundaries." }
            Default {}
        }
        $expert = [LanguageModel]::new($name, $supplement)
        $experts += $expert
    }

    # Start discussion rounds
    for ($round = 1; $round -le $rounds; $round++) {
        Write-Host "Round $round"

        # Moderator asks question
        $question = "What are your two thoughts on the topic '$topic'?"
        $moderatorResponse = $moderator.InvokeLLM("Welcome all experts to discussion about '$topic'")
        Write-Host "Moderator: $moderatorResponse" -ForegroundColor Green

        # Each expert responds
        foreach ($expert in $experts) {
            $lastMemoryElement = $expert.GetLastNMemoryElements(1)
            if ($lastMemoryElement) {
                $lastMemoryElement = "`nYour last response was:`n"+$($lastMemoryElement.trim())
            }
            $expertResponse = $expert.InvokeLLM($question+$lastMemoryElement)
            Write-Host "$($expert.name): $expertResponse" 
            $lastMemoryElement = ""
        }
    }

    # Print experts' memories
    foreach ($expert in $experts) {
        #Write-Host "$($expert.name)'s Memory:" -ForegroundColor Blue
        #Write-Host ($expert.memory) -ForegroundColor Blue
        #Write-Host ""
        Write-Host "$($expert.name)'s summarized memory:" -BackgroundColor Blue
        write-Host ($moderator.InvokeLLM("Summarize: $($expert.memory)")) -BackgroundColor Blue
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
