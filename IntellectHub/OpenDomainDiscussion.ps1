[CmdletBinding()]
param(
    [string] $Topic = "The Impact of GPT on IT Microsoft Administrators",
    [int] $Rounds = 2,
    [int] $expertCount = 2,
    [switch] $Thoughts
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
            #$prompt = $prompt + "`n`n" + $this.supplementary_information
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

$noteModerator = @"
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

    $ExpertPromptJSON = @"
You must respond by filling in the appropriate JSON object key values:
``````json
{
    "context": {"backgroundandscope": ""},
    "objectives": {"goalsandoutcomes": ""},
    "content": {"mainPoints": "", "relevance": ""},
    "analysis": {"strengths": "", "weaknesses": "", "credibility": ""},
    "implications": {"practical": "", "future": ""},
    "communication": {"clarityandengagement": ""}
}
``````
"@
    
    # Loop to create different types of expert language models
    for ($i = 1; $i -le 5; $i++) {
        # Switch case to assign different roles and instructions to the experts
        switch ($i) {
            1 {
                # Domain Expert role
                $name = "Domain Expert"; 
                $supplement = @"
"@ 

                $ExpertPrompt = @"
###Instructions###
You are $name with the following skills and qualifications: Deep knowledge of the specific field or industry, Ability to synthesize complex information, Strong research and analytical skills, Excellent communication skills. Your main task is to analyze the topic text `"$topic`", and other data: 
{0}
Cover the six key aspects below.
1. Context:
   - Background and Scope
2. Objectives:
   - Goals and outcomes
3. Content:
   - Main points
   - Relevance
4. Analysis:
   - Strengths
   - Weaknesses
   - Credibility
5. Implications:
   - Practical
   - Future directions
6. Communication:
    - Clarity and engagement

"@

            }
            2 {
                # Data Analyst role
                $name = "Data Analyst"; 

                $supplement = @"
"@

                $ExpertPrompt = $ExpertPrompt.Replace("Domain Expert", "Data Analyst").Replace("Deep knowledge of the specific field or industry", "Proficiency in data analysis and statistical tools").Replace("Ability to synthesize complex information", "Strong understanding of data visualization techniques").Replace("Strong research and analytical skills", "Ability to interpret and explain data insights").Replace("Excellent communication skills", "Experience with data-driven decision making")
            }
            3 {
                # Creative Thinker role
                $name = "Creative Thinker"; 
                $supplement = @"
"@ 


                $ExpertPrompt = $ExpertPrompt.Replace("Domain Expert", "Creative Thinker").Replace("Deep knowledge of the specific field or industry", "Strong brainstorming and ideation skills").Replace("Ability to synthesize complex information", "Ability to think outside the box").Replace("Strong research and analytical skills", "Excellent problem-solving skills").Replace("Excellent communication skills", "Strong communication and storytelling abilities")

            }
            4 {
                # Psychologist role
                $name = "Psychologist"; 
                $supplement = @"
"@

                $ExpertPrompt = $ExpertPrompt.Replace("Domain Expert", "Psychologist").Replace("Deep knowledge of the specific field or industry", "In-depth understanding of human behavior and mental processes").Replace("Ability to synthesize complex information", "Experience with qualitative and quantitative research methods").Replace("Strong research and analytical skills", "Strong analytical and interpretative skills").Replace("Excellent communication skills", "Excellent communication and empathy skills")

            }
            5 {
                # Facilitator role
                $name = "Facilitator"; 
                $supplement = @"
"@ 


                $ExpertPrompt = $ExpertPrompt.Replace("Domain Expert", "Facilitator").Replace("Deep knowledge of the specific field or industry", "Strong leadership and mediation skills").Replace("Ability to synthesize complex information", "Ability to guide discussions and ensure productive outcomes").Replace("Strong research and analytical skills", "Excellent communication and conflict resolution skills").Replace("Excellent communication skills", "Experience with group dynamics and teamwork")

            }
            Default {}
        }
        # Create a new language model with the assigned role and instructions
        $expert = [LanguageModel]::new($name, $supplement)
        # Add the new expert to the experts array
        $experts += $expert
    }
    # Randomly select a number of experts based on the expertCount parameter
    $experts = $experts | get-random -Count $expertCount
    write-host ($experts.name -join ", ")

    # Start discussion rounds
    for ($round = 1; $round -le $rounds; $round++) {
        Write-Host "Round $round" -BackgroundColor White -ForegroundColor Blue

        $ModeratorMemory = $($moderator.GetLastNMemoryElements(1)).foreach{ Clear-LLMDataJSON $_ }
        $ExpertsMemory = ""
        foreach ($expert in $experts) {
            $lastMemoryElementJSON = $($expert.GetLastNMemoryElements(1)).foreach{ Clear-LLMDataJSON $_ }
            if ($lastMemoryElementJSON) {
                $lastMemoryElementObj = $lastMemoryElementJSON | ConvertFrom-Json
                $ExpertsMemory += @"
$($expert.name) response:
    context: 
    - backgroundandscope: $($lastMemoryElementObj.context.backgroundandscope)
objectives: 
    - goalsandoutcomes: $($lastMemoryElementObj.context.backgroundandscope)
content: 
    - mainPoints: $($lastMemoryElementObj.content.mainPoints)
    - relevance: $($lastMemoryElementObj.content.relevance)
analysis:
    - strengths: $($lastMemoryElementObj.analysis.strengths) 
    - weaknesses: $($lastMemoryElementObj.analysis.weaknesses)
    - credibility: $($lastMemoryElementObj.analysis.credibility)
implications:
    - practical: $($lastMemoryElementObj.implications.practical)
    - future: $($lastMemoryElementObj.implications.future)
communication:
    - clarityandengagement: $($lastMemoryElementObj.communication.clarityandengagement)

"@
            }
        }

        $moderatorPrompt = @"
###Instructions###
You are Moderator with the following skills: Strong leadership, excellent communication, conflict resolution, experience in group dynamics and teamwork. 
Your main task is to facilitate and analyze the topic `"$($topic.trim())`" and other data:
$ExpertsMemory
Cover the five key points below. 
1. Context:
   - Background and scope
2. Key Points:
   - Main points discussed
   - Participant contributions
3. Flow:
   - Discussion progression
   - Key transitions
4. Analysis:
   - Major insights
   - Consensus and disagreements
5. Outcome:
   - Summary of conclusions
   - Next steps

   You must respond in JSON format only:
``````json
{
    "context": {"backgroundandscope": ""},
    "keyPoints": {"mainPoints": "", "contributions": ""},
    "flow": {"progression": "", "transitions": ""},
    "analysis": {"insights": "", "consensus": "", "disagreements": ""},
    "outcome": {"summary": "", "nextSteps": ""}
}
``````
"@


        $moderatorResponse = $moderator.InvokeLLM($moderatorPrompt)
        $moderatorResponseJSON = Clear-LLMDataJSON $moderatorResponse
        $moderatorResponseObj = $moderatorResponseJSON | convertfrom-json
        if (-not $Thoughts) {
            Write-Host "Moderator: $moderatorResponse" -ForegroundColor Green
            #$moderatorResponseJSON
            #$moderatorResponseObj
        }
        else {
            Write-Host $moderatorResponseObj.Topic -ForegroundColor Green
            Write-Host $moderatorResponseObj.required_action -ForegroundColor Green
            Write-Host ($moderatorResponseObj.questions_for_experts -join "`n") -ForegroundColor Green
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
            $lastMemoryElement = $($expert.GetLastNMemoryElements(1)).foreach{ Clear-LLMDataJSON $_ }
            $ModeratorMemoryJSON = $($moderator.GetLastNMemoryElements(1)).foreach{ Clear-LLMDataJSON $_ }
            $ModeratorMemoryObj = $ModeratorMemoryJSON | ConvertFrom-Json
            if ($lastMemoryElement -or $ModeratorMemoryJSON) {
                $lastMemoryElement = @"
$lastMemoryElement
Memory of Moderator:
Context: 
    - background and scope: $($ModeratorMemoryObj.context.backgroundandscope)
KeyPoints: 
    - mainPoints: $($ModeratorMemoryObj.KeyPoints.mainPoints)
    - contributions: $($ModeratorMemoryObj.KeyPoints.contributions)
flow: 
    - progression: $($ModeratorMemoryObj.flow.progression)
    - transitions: $($ModeratorMemoryObj.flow.transitions)
analysis: 
    - insights: $($ModeratorMemoryObj.analysis.insights)
    - consensus: $($ModeratorMemoryObj.analysis.consensus)
    - disagreements: $($ModeratorMemoryObj.analysis.disagreements)
outcome: 
    - summary: $($ModeratorMemoryObj.outcome.summary)
    - nextSteps: $($ModeratorMemoryObj.outcome.nextSteps)
  
"@

            }
            $questionWithmemory = $($ExpertPrompt -f $lastMemoryElement)
            $questionWithmemory += $ExpertPromptJSON
            $expertResponse = $expert.InvokeLLM($questionWithmemory)
            $expertResponseJSON = Clear-LLMDataJSON $expertResponse
            $expertResponseObj = $expertResponseJSON | ConvertFrom-Json
            #$expertResponse = Extract-JSON $expertResponse | ConvertFrom-Json
            if (-not $Thoughts) {
                Write-Host "$($expert.name): $expertResponse" 
                #$expertResponseJSON
                #$expertResponseObj
            }
            else {
                Write-Host $($expertResponseObj.Thoughts -join "`n")
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
    Write-Host "Summarize" -BackgroundColor White -ForegroundColor Blue

    # Print experts' memories
    foreach ($expert in $experts) {
        #Write-Host "$($expert.name)'s Memory:" -ForegroundColor Blue
        #Write-Host ($expert.memory) -ForegroundColor Blue
        #Write-Host ""
        $ExpertMemory = $($expert.memory).foreach{ Clear-LLMDataJSON $_ }
        $Summarize = @"
###Instruction###
As a Great Knowledge Orchestrator do analyze the memory data, and create a long-form content response that combines the most relevant and interesting information. Remove information aboout experts. Analyze memory data and improve your response.

###Memory###
$ExpertMemory

$noteModerator
"@
        $expertSummarize = $expert.InvokeLLM($Summarize)
        $expertSummarizeJSON = Clear-LLMDataJSON $expertSummarize
        $expertSummarizeObj = $expertSummarizeJSON | ConvertFrom-Json
        if (-not $Thoughts) {
            Write-Host "$($expert.name)'s summarized memory:" -BackgroundColor Blue
            #write-Host ($moderator.InvokeLLM($Summarize)) -BackgroundColor Blue
            write-Host $expertSummarize -BackgroundColor Blue
            #$expertSummarizeJSON
            #$expertSummarizeObj
        }
        else {
            Write-Host $expertSummarizeObj.Thoughts
            Write-Host $expertSummarizeObj.Topic_answers
        }
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $filename = "Summarize-$($expert.name)-prompt-$timestamp.txt"
        $filepath = Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $filename
        $Summarize | Out-File -FilePath $filepath
        $filename = "Summarize-$($expert.name)-response-$timestamp.txt"
        $filepath = Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $filename
        $expertSummarize | Out-File -FilePath $filepath

    }

    # General summarization
    foreach ($expert in $experts) {
        $generalMemory += $($expert.GetLastNMemoryElements(1)).foreach{ Clear-LLMDataJSON $_ }
    }
    $Summarize = @"
###Instruction###
As a Great Knowledge Orchestrator you must do the task to answer the topic based on memory of discussion. Examine given data and create comprehensive and detailed final answer. Prioritize information directly relevant to the user's Topic.

###Topic###
$topic

###Memory###
$generalMemory


"@

    $NewSupplement = @"

Display response as JSON object only with given keys: '{ "Topic": "", "Key_points": [ "" ], "Topic_answers": [ "" ], "Final_Answer": ""}'
"@
    Write-Host "Finalizing" -BackgroundColor White -ForegroundColor Blue
    $moderator.supplementary_information = $NewSupplement
    $Summarize += $NewSupplement
    $FinalResponse = $moderator.InvokeLLM($Summarize)
    #write-Host ($FinalResponse) -BackgroundColor Green
    $FinalResponseJSON = Clear-LLMDataJSON $FinalResponse 
    $FinalResponseObj = $FinalResponseJSON | ConvertFrom-Json
    Write-Host "Topic:" -BackgroundColor DarkGreen
    Write-Host $($FinalResponseObj.Topic)
    Write-Host "Topic's answers:" -BackgroundColor DarkGreen
    foreach ($Answers in $FinalResponseObj.Topic_answers) {
        Write-Host " - $Answers"
    }

    #Write-Host "Thoughts:"
    foreach ($thought in $FinalResponseObj.Thoughts) {
        #Write-Host " - $thought"
    }
    #Write-Host "Other:"
    foreach ($other in $FinalResponseObj.Other) {
        #Write-Host " - $other"
    }
    #Write-Host "Combined:"
    foreach ($Combined in $FinalResponseObj.Combined) {
        #Write-Host " - $Combined"
    }
    Write-Host "Key_points:" -BackgroundColor DarkGreen
    foreach ($Key_points in $FinalResponseObj.Key_points) {
        Write-Host " - $Key_points"
    }
    Write-Host "Final answer:" -BackgroundColor DarkGreen
    Write-Host $($FinalResponseObj.Final_Answer)
    
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
