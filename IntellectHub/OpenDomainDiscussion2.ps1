[CmdletBinding()]
param(
    [string] $Topic = "Explain impact of GPT on IT Microsoft Administrators",
    [int] $Rounds = 2,
    [int] $expertCount = 2,
    [switch] $Thoughts,
    [bool] $Stream = $false
)

# Define Language Model class
class LanguageModel {
    [string] $name
    [string] $ExpertPrompt
    [string[]] $memory

    LanguageModel([string] $name, $ExpertPrompt) {
        $this.name = $name
        $this.ExpertPrompt = $ExpertPrompt
        $this.memory = @()
    }

    [string] InvokeLLM([string] $prompt, [bool] $Stream) {
        try {
            # Simulate language model response
            write-host $prompt -ForegroundColor DarkYellow
            $arguments = @($prompt, 3000, "Precise", $this.name, "udtgpt35turbo", $true)
            $response = Invoke-PSAOAICompletion @arguments -LogFolder $script:TeamDiscussionDataFolder -verbose:$false -Stream $Stream
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
$moderator = [LanguageModel]::new("Moderator", "")

# Define a function to conduct the discussion
function Conduct-Discussion {
    param (
        [string] $topic,
        [int] $rounds,
        [int] $expertCount
    )

    # Create expert language models
    $experts = @()

    $responseGuide = "The scaffolding of a response is a JSON object with any key structure. Add key 'questions'.`nYou provide a thorough, insightful, and forward-thinking data analysis. Set clear goal to respond to the topic. Add questions, and with answer to ones, if any. Use CoT, and professional tone in your response."
       

    # Loop to create different types of expert language models
    for ($i = 0; $i -le 4; $i++) {
        # Switch case to assign different roles and instructions to the experts
        switch ($i) {
            0 {
                # Domain Expert role
                $name = "Domain Expert"; 
                $ExpertPrompt_ = @"
You are in role of $name with the following skills and qualifications: Deep knowledge of the domain, Ability to synthesize complex information, Strong research and analytical skills, Excellent communication skills. Your main task is to respond to the topic '$($topic.trim())' based on the available data.
{0}
$responseGuide

"@
                $ExpertPrompt = $ExpertPrompt_
            }
            1 {
                # Data Analyst role
                $name = "Data Analyst"; 
                $ExpertPrompt = $ExpertPrompt_.Replace("Domain Expert", "Data Analyst").Replace("Deep knowledge of the domain", "Proficiency in data analysis and statistical tools").Replace("Ability to synthesize complex information", "Strong understanding of data visualization techniques").Replace("Strong research and analytical skills", "Ability to interpret and explain data insights").Replace("Excellent communication skills", "Experience with data-driven decision making")
            }
            2 {
                # Creative Thinker role
                $name = "Creative Thinker"; 
                $ExpertPrompt = $ExpertPrompt_.Replace("Domain Expert", "Creative Thinker").Replace("Deep knowledge of the domain", "Strong brainstorming and ideation skills").Replace("Ability to synthesize complex information", "Ability to think outside the box").Replace("Strong research and analytical skills", "Excellent problem-solving skills").Replace("Excellent communication skills", "Strong communication and storytelling abilities")

            }
            3 {
                # Psychologist role
                $name = "Psychologist"; 
                $ExpertPrompt = $ExpertPrompt_.Replace("Domain Expert", "Psychologist").Replace("Deep knowledge of the domain", "In-depth understanding of human behavior and mental processes").Replace("Ability to synthesize complex information", "Experience with qualitative and quantitative research methods").Replace("Strong research and analytical skills", "Strong analytical and interpretative skills").Replace("Excellent communication skills", "Excellent communication and empathy skills")

            }
            4 {
                # Facilitator role
                $name = "Facilitator"; 
                $ExpertPrompt = $ExpertPrompt_.Replace("Domain Expert", "Facilitator").Replace("Deep knowledge of the domain", "Strong leadership and mediation skills").Replace("Ability to synthesize complex information", "Ability to guide discussions and ensure productive outcomes").Replace("Strong research and analytical skills", "Excellent communication and conflict resolution skills").Replace("Excellent communication skills", "Experience with group dynamics and teamwork")

            }
            Default {}
        }
        # Create a new language model with the assigned role and instructions
        $expert = [LanguageModel]::new($name, $ExpertPrompt)
        # Add the new expert to the experts array
        $experts += $expert
    }
    $expert = ""
    #$experts | ConvertTo-Json
    # Randomly select a number of experts based on the expertCount parameter
    #$experts = $experts | get-random -Count $expertCount
    $experts = $experts[0, 2]
    write-host ($experts.name -join ", ")

    # Start discussion rounds
    for ($round = 1; $round -le $rounds; $round++) {
        Write-Host "Round $round" -BackgroundColor DarkGreen
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
        if ((-not [string]::IsNullOrWhiteSpace($ExpertsMemory)) -or (-not [string]::IsNullOrWhiteSpace($ModeratorMemory)) ) {
            $moderatorPromptData = @"
Data:
###
{0}
{1}
###
"@
            $moderatorPromptData = ($moderatorPromptData -f $ModeratorMemoryData.trim(), $ExpertsMemory.trim())
        } 

        $responseGuideModerator = @"
Before you answer, you need to do:
    - thorough, insightful, and forward-thinking data analysis using Chain of Thoughts,
    - set clear goal to respond to the topic,
    - answer questions, if any,
    - add your own questions to the topic.
Response focusing only on the topic goal. Use a professional tone in response. The scaffolding of a response is a JSON object with any key structure.
"@

        $moderatorPrompt = @"
You are a $($moderator.name) with the following skills: basic domain knowledge, excellent communication, conflict resolution, experience in group dynamics and teamwork.
Your main task is to answer the topic '$($topic.trim())' based on the available data.
{0}
$responseGuideModerator

"@
        if (-not [string]::IsNullOrWhiteSpace($ExpertsMemory) ) {
            $moderatorPrompt = $moderatorPrompt -f $moderatorPromptData
        }
        else {
            $moderatorPrompt = $moderatorPrompt -f $null
        }
        Write-Host $moderator.name -BackgroundColor White -ForegroundColor Blue -NoNewline
        $moderatorResponse = $moderator.InvokeLLM($moderatorPrompt, $Stream)
        if (-not $stream) { 
            Write-Host $moderatorResponse -ForegroundColor Green 
        } 
        while (-not (Test-IsValidJson -jsonString $moderatorResponse) -or [string]::IsNullOrEmpty($moderatorResponse)) {
            if (-not $stream) {
                Write-Color "TextToJSON conversion..." -BackgroundColor Blue -NoNewline -ShowTime
            }
            else {
                Write-Color "TextToJSON conversion..." -BackgroundColor Blue  -ShowTime
            }
            $moderatorResponseJSON = AIConvertto-Json -text $moderatorResponse -Entity $moderator -Stream $Stream
            if (Test-IsValidJson -jsonString $moderatorResponseJSON) {
                $moderatorResponse = $moderatorResponseJSON
                break
            }
            Write-Host "Sleeping 10 seconds to keep TPM in limit." -BackgroundColor DarkMagenta
            Start-Sleep -Seconds 10
        }
        if (Test-IsValidJson -jsonString $moderatorResponse) {
            $Questions = SearchIn-Json -json ($moderatorResponse) -key "questions"
            if ($Questions) {
                Write-Host "Questions" -ForegroundColor DarkGray
                Write-Host ($questions -join "`n") -ForegroundColor Gray
                $QuestionsArray += $Questions
            }
        }
        $Questions = ""

        #$moderatorResponseObj
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
            foreach ($expert_ in $experts) {
                $lastMemoryElement = $($expert_.GetLastNMemoryElements(1))
                if ($lastMemoryElement) {
                    $ExpertsMemory += @"
$($lastMemoryElement.trim())
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

            $questionWithmemory = $($expert.ExpertPrompt -f $(Remove-EmptyLines $($expertpromptData -f $lastMemoryElement.trim())))
            Write-Host $($expert.name) -BackgroundColor White -ForegroundColor Blue -NoNewline
            $expertResponse = $expert.InvokeLLM($questionWithmemory, $Stream)
            #$expertResponse = Extract-JSON $expertResponse | ConvertFrom-Json
            if (-not $stream) { 
                Write-Host $expertResponse -ForegroundColor DarkBlue
            }
            while (-not (Test-IsValidJson -jsonString $expertResponse) -or [string]::IsNullOrEmpty($expertResponse)) {
                if (-not $stream) {
                    Write-Color "TextToJSON conversion..." -BackgroundColor Blue -NoNewline  -ShowTime
                }
                else {
                    Write-Color "TextToJSON conversion..." -BackgroundColor Blue  -ShowTime
                }
                $expertResponseJSON = AIConvertto-Json -text $expertResponse -Entity $moderator -Stream $Stream
                if (Test-IsValidJson -jsonString $expertResponseJSON) {
                    $expertResponse = $expertResponseJSON
                    break
                }
                Write-Host "Converting to JSON. Sleep 10 seconds" -BackgroundColor DarkMagenta
                Start-Sleep -Seconds 10
            }
            if (Test-IsValidJson -jsonString $expertResponse) {
                $questions = SearchIn-Json -json ($expertResponse) -key "questions"
                if ($questions) {
                    Write-Host "Questions" -ForegroundColor Gray
                    Write-Host ($questions -join "`n") -ForegroundColor Gray
                    $QuestionsArray += $Questions
                }
            }
            $Questions = ""
            #$expertResponseJSON
            #$expertResponseObj

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


    foreach ($expert_ in $experts) {
        $lastMemoryElement = $($expert_.GetLastNMemoryElements(1))
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
You must do summarization:
1. Summarization & Analysis:
    - Task: Analyze the provided data and identify the key points that directly address the topic.
    - Focus: Focus on the information most relevant to answering the question comprehensively, if any.
    - Output: Generate a concise summary that incorporates these key points in a clear and well-organized manner. Do not show the summary, yet.
2. Answer Formulation:
    - Task: Based on the summarized information, formulate a direct and informative answer to the topic.
    - Focus: Ensure the answer directly addresses thetopic and avoids unnecessary conversational elements.
$questionWithmemory
Use a professional tone in response. The scaffolding of a response is a JSON object with any key structure.
"@
    #Use professional tone. You must use only JSON object output when responding {`"response`": `"`"}.

    Write-Host "Finalizing" -BackgroundColor White -ForegroundColor Blue  -NoNewline
    #$Summarize += $NewSupplement
    $FinalResponse = $moderator.InvokeLLM($Summarize, $Stream)
    if (-not $stream) { 
        Write-Color $FinalResponse -Color DarkBlue -BackGroundColor DarkGreen -LinesBefore -ShowTime
    }
    if (-not [string]::IsNullOrEmpty($FinalResponse)) {
        while (-not (Test-IsValidJson -jsonString $FinalResponse)) {
            if (-not $stream) {
                Write-Color "TextToJSON conversion..." -BackgroundColor Blue -NoNewline  -ShowTime
            }
            else {
                Write-Color "TextToJSON conversion..." -BackgroundColor Blue  -ShowTime
            }
            $FinalResponseJSON = AIConvertto-Json -text $FinalResponse -Entity $moderator -Stream $Stream
            if (Test-IsValidJson -jsonString $FinalResponseJSON) {
                $FinalResponse = $FinalResponseJSON
                break
            }
            Write-Host "Converting to JSON. Sleep 10 seconds" -BackgroundColor DarkMagenta
            Start-Sleep -Seconds 5
        }
        if (Test-IsValidJson -jsonString $FinalResponse) {
            $Questions = SearchIn-Json -json ($FinalResponse) -key "questions"
            if ($Questions) {
                Write-Host "Questions" -ForegroundColor Gray
                Write-Host ($questions -join "`n") -ForegroundColor Gray        
                $QuestionsArray += $Questions
            }
        }
    } else {
        Write-Warning "Empty response fot Finalizing"
    }

    $Questions = ""

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

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $filename = "Questions-$timestamp.txt"
    $filepath = Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $filename
    $QuestionsArray | ConvertTo-Json | Out-File -FilePath $filepath

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
$QuestionsArray = @()

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
