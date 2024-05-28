[CmdletBinding()]
param(
    [string] $Topic = "Explain impact of GPT on IT Microsoft Administrators",
    [int] $Rounds = 2,
    [int] $expertCount = 2,
    [switch] $Thoughts
)

# Define Language Model class
class LanguageModel {
    [string] $name
    [string[]] $memory

    LanguageModel([string] $name) {
        $this.name = $name
        $this.memory = @()
    }

    [string] InvokeLLM([string] $prompt) {
        try {
            # Simulate language model response
            write-host $prompt -ForegroundColor DarkYellow
            $arguments = @($prompt, 3000, "Precise", $this.name, "udtgpt35turbo", $true)
            $response = Invoke-PSAOAICompletion @arguments -LogFolder $script:TeamDiscussionDataFolder -verbose:$false
            $this.memory += $response
            #return "This is $($this.name)'s response to:`n$($prompt)`n '$response'"
            #return "This is $($this.name)'s response:`n===`n$($response.trim())`n==="
            return $response

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
$moderator = [LanguageModel]::new("Moderator")

# Define a function to conduct the discussion
function Conduct-Discussion {
    param (
        [string] $topic,
        [int] $rounds,
        [int] $expertCount
    )

    # Create expert language models
    $experts = @()
    
    # Loop to create different types of expert language models
    for ($i = 1; $i -le 5; $i++) {
        # Switch case to assign different roles and instructions to the experts
        switch ($i) {
            1 {
                # Domain Expert role
                $name = "Domain Expert"; 
                $ExpertPrompt = @"
You are $name with the following skills and qualifications: Deep knowledge of the domain, Ability to synthesize complex information, Strong research and analytical skills, Excellent communication skills. Your main task is to focus to build answer for topic $($topic.trim()). To do that you MUST analyze the data and answer questions, if any. Enrich your response with creative insights, innovative ideas, and deep analytical thoughts. Aim to provide a thorough, insightful, and forward-thinking analysis to answer the best way to the topic.
{0}
Use clear language.
"@

            }
            2 {
                # Data Analyst role
                $name = "Data Analyst"; 
                $ExpertPrompt = $ExpertPrompt.Replace("Domain Expert", "Data Analyst").Replace("Deep knowledge of the domain", "Proficiency in data analysis and statistical tools").Replace("Ability to synthesize complex information", "Strong understanding of data visualization techniques").Replace("Strong research and analytical skills", "Ability to interpret and explain data insights").Replace("Excellent communication skills", "Experience with data-driven decision making")
            }
            3 {
                # Creative Thinker role
                $name = "Creative Thinker"; 
                $ExpertPrompt = $ExpertPrompt.Replace("Domain Expert", "Creative Thinker").Replace("Deep knowledge of the domain", "Strong brainstorming and ideation skills").Replace("Ability to synthesize complex information", "Ability to think outside the box").Replace("Strong research and analytical skills", "Excellent problem-solving skills").Replace("Excellent communication skills", "Strong communication and storytelling abilities")

            }
            4 {
                # Psychologist role
                $name = "Psychologist"; 
                $ExpertPrompt = $ExpertPrompt.Replace("Domain Expert", "Psychologist").Replace("Deep knowledge of the domain", "In-depth understanding of human behavior and mental processes").Replace("Ability to synthesize complex information", "Experience with qualitative and quantitative research methods").Replace("Strong research and analytical skills", "Strong analytical and interpretative skills").Replace("Excellent communication skills", "Excellent communication and empathy skills")

            }
            5 {
                # Facilitator role
                $name = "Facilitator"; 
                $ExpertPrompt = $ExpertPrompt.Replace("Domain Expert", "Facilitator").Replace("Deep knowledge of the domain", "Strong leadership and mediation skills").Replace("Ability to synthesize complex information", "Ability to guide discussions and ensure productive outcomes").Replace("Strong research and analytical skills", "Excellent communication and conflict resolution skills").Replace("Excellent communication skills", "Experience with group dynamics and teamwork")

            }
            Default {}
        }
        # Create a new language model with the assigned role and instructions
        $expert = [LanguageModel]::new($name)
        # Add the new expert to the experts array
        $experts += $expert
    }
    # Randomly select a number of experts based on the expertCount parameter
    $experts = $experts | get-random -Count $expertCount
    write-host ($experts.name -join ", ")
    # Start discussion rounds
    for ($round = 1; $round -le $rounds; $round++) {
        Write-Host "Round $round" -BackgroundColor White -ForegroundColor Blue
        $ExpertsMemory = ""

        $ModeratorMemory = Remove-EmptyLines $($moderator.GetLastNMemoryElements(1))
        if ($ModeratorMemory) {
            $ModeratorMemoryData = @"
$ModeratorMemory
"@
        }
        
        foreach ($expert in $experts) {
            $lastMemoryElement = $($expert.GetLastNMemoryElements(1))
            if ($lastMemoryElement) {
                $ExpertsMemory += @"
$($lastMemoryElement.trim())
"@
                
            }
        }
        [string]::IsNullOrWhiteSpace($ExpertsMemory)
        [string]::IsNullOrWhiteSpace($ModeratorMemory)
        if (-not [string]::IsNullOrWhiteSpace($ExpertsMemory) -or [string]::IsNullOrWhiteSpace($ModeratorMemory) ) {
            $moderatorPromptData = @"
Data:
###
{0}
{1}
###
"@
            $moderatorPromptData = ($moderatorPromptData -f $ModeratorMemoryData.trim(), $ExpertsMemory.trim())
        } 
        $moderatorPrompt = @"
You are Moderator with the following skills: Strong leadership, excellent communication, conflict resolution, experience in group dynamics and teamwork. 
Your main task is to focus to build answer to topic $($topic.trim()). To do that you MUST facilitate and analyze the topic, and other data, if any. Enrich your response with creative insights, innovative ideas, and deep analytical thoughts. Aim to provide a thorough, insightful, and forward-thinking analysis.
{0}
Use clear language.
"@
        if (-not [string]::IsNullOrWhiteSpace($ExpertsMemory) ) {
            $moderatorPrompt = $moderatorPrompt -f $moderatorPromptData
        }
        else {
            $moderatorPrompt = $moderatorPrompt -f $null
        }
        $moderatorResponse = $moderator.InvokeLLM($moderatorPrompt)

        if (-not $Thoughts) {
            Write-Host "Moderator: $moderatorResponse" -ForegroundColor Green
            #$moderatorResponseJSON
            #$moderatorResponseObj
        }
        else {
            Write-Host $moderatorResponse -ForegroundColor Green
        }
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $filename = "$round-$($moderator.name)-prompt-$timestamp.txt"
        $filepath = Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $filename
        $moderatorPrompt | Out-File -FilePath $filepath
        $filename = "$round-$($moderator.name)-response-$timestamp.txt"
        $filepath = Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $filename
        $moderatorResponse | Out-File -FilePath $filepath

        $lastMemoryElement = ""
        # Each expert responds
        foreach ($expert in $experts) {
            $ExpertsMemory = ""   
            foreach ($expert in $experts) {
                $lastMemoryElement = $($expert.GetLastNMemoryElements(1))
                if ($lastMemoryElement) {
                    $ExpertsMemory += @"
$lastMemoryElement
"@
                    
                }
            }
    

            #$lastMemoryElement = $($expert.GetLastNMemoryElements(1))
            $ModeratorMemory = $($moderator.GetLastNMemoryElements(1))
            if ($lastMemoryElement -or $ModeratorMemory) {
                $lastMemoryElement = @"
Data:
###
$ModeratorMemory
$ExpertsMemory
###
"@

            }
            $expertpromptData = @"
{0}
"@
            $questionWithmemory = $($ExpertPrompt -f $(Remove-EmptyLines $($expertpromptData -f $lastMemoryElement.trim())))
            $expertResponse = $expert.InvokeLLM($questionWithmemory)
            #$expertResponse = Extract-JSON $expertResponse | ConvertFrom-Json
            if (-not $Thoughts) {
                Write-Host "$($expert.name): $expertResponse" 
                #$expertResponseJSON
                #$expertResponseObj
            }
            else {
                Write-Host $expertResponse
            }
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $filename = "$round-$($expert.name)-prompt-$timestamp.txt"
            $filepath = Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $filename
            $questionWithmemory | Out-File -FilePath $filepath
            $filename = "$round-$($expert.name)-response-$timestamp.txt"
            $filepath = Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $filename
            $expertResponse | Out-File -FilePath $filepath
                    
            $lastMemoryElement = ""
            $questionWithmemory = ""
            $questionWithmemory = ""
            $expertResponse = ""
            $questionWithmemory = ""
        }
        $moderatorPrompt = ""
        $moderatorResponse = ""
    }
    foreach ($expert in $experts) {
        $lastMemoryElement = $($expert.GetLastNMemoryElements(1))
        if ($lastMemoryElement) {
            $ExpertsMemory += @"
$lastMemoryElement
"@
            
        }
    }


    #$lastMemoryElement = $($expert.GetLastNMemoryElements(1))
    $ModeratorMemory = $($moderator.GetLastNMemoryElements(1))
    if ($lastMemoryElement -or $ModeratorMemory) {
        $lastMemoryElement = @"
Data:
###
$ModeratorMemory
$ExpertsMemory
###
"@

    }
    $expertpromptData = @"
{0}
"@
    $questionWithmemory = $($expertpromptData -f $lastMemoryElement)

    $Summarize = @"
We've had a thought-provoking discussion about $topic, and now it's time to synthesize what we've learned!
Crafting the Big Picture:
Recap the Key Points: Briefly summarize the main discussion points. Use clear, concise language and incorporate key phrases or data mentioned by participants.
Weaving the Threads: Explain how the different perspectives and information shared relate to the original topic. Did the discussion reveal new aspects, or solidify existing knowledge?
Towards an Answer: Based on the collective insights, craft an answer (or multiple perspectives if applicable) to the original question about the topic.
$questionWithmemory
Use clear language.
"@


    Write-Host "Finalizing" -BackgroundColor White -ForegroundColor Blue
    #$Summarize += $NewSupplement
    $FinalResponse = $moderator.InvokeLLM($Summarize)
    #write-Host ($FinalResponse) -BackgroundColor Green
    Write-Host "Answer:" -BackgroundColor DarkGreen
    Write-Host $FinalResponse

    #Write-Host "Key Findings:" -BackgroundColor DarkGreen
    #Write-Host $($FinalResponseObj.keyFindings.insights)
    #Write-Host $($FinalResponseObj.keyFindings.strengths)
    #Write-Host $($FinalResponseObj.keyFindings.weaknesses)

    #Write-Host "Recommendations:" -BackgroundColor DarkGreen
    #Write-Host $($FinalResponseObj.recommendations.actions)
    #Write-Host $($FinalResponseObj.recommendations.futureConsiderations)
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $filename = "Final-$($moderator.name)-prompt-$timestamp.txt"
    $filepath = Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $filename
    $Summarize | Out-File -FilePath $filepath
    $filename = "Final-$($moderator.name)-response-$timestamp.txt"
    $filepath = Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $filename
    $FinalResponse | Out-File -FilePath $filepath

    # Provide a general response related to the user's topic
    #$generalResponse = "In conclusion, regarding the topic '$topic', the experts have provided valuable insights."
    #Write-Host $generalResponse

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
