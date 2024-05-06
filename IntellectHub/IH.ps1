[CmdletBinding()]
param(
    [string]$usermessage
)

# Import PSaoAI module
[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "0", "User")
#Import-Module -Name PSaoAI
Import-module "D:\dane\voytas\Dokumenty\visual_studio_code\github\AzureOpenAI-PowerShell\PSAOAI\PSAOAI.psd1" -Force 
import-module PSWriteColor

$IHGUID = [System.Guid]::NewGuid().ToString()


#region Importing Modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$entityClassPath = Join-Path -Path $scriptPath -ChildPath "entity_class.ps1"
$helperFunctionsPath = Join-Path -Path $scriptPath -ChildPath "helper_functions.ps1"
Try {
    . $helperFunctionsPath
    PSWriteColor\Write-Color -Text "Imported helper function file" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
}
Catch {
    Write-Error -Message "Failed to import helper function file"
    return $false
}

Try {
    . $entityClassPath
    PSWriteColor\Write-Color -Text "Imported entity class" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
}
Catch {
    Write-Error -Message "Failed to import entity class"
    return $false
}
#endregion


#region Importing Experts Data
Try {
    $experts = Get-ExpertsFromJson -FilePath "experts.json"
    if ($experts) {
        PSWriteColor\Write-Color -Text "Imported experts data ($($experts.count))" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Error -Message "Failed to import experts data"
    return $false
}
#endregion


#region Importing Discussion Steps
Try {
    $discussionSteps = Get-DiscussionStepsFromJson -FilePath "discussion_steps6.json"

    if ($discussionSteps) {
        PSWriteColor\Write-Color -Text "Discussion steps was loaded ($($discussionSteps.count))" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Error -Message "Failed to load discussion steps"
    return $false
}
#endregion


#region Creating Main Entity
Try {
    $mainEntity = Build-EntityObject -Name "Orchestrator" -Role "Project Manager" -Description "Manager of experts" -Skills @("Organization", "Communication", "Problem-Solving") -GPTType "azure" -GPTModel "udtgpt35turbo"

    if ($mainEntity) {
        PSWriteColor\Write-Color -Text "Main Entity was created" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Error -Message "Failed to create Orchestrator Entity"
    return $false
}
#endregion


#region Creating Team Discussion Folder
Try {
    # Get the current date and time
    $currentDateTime = Get-Date -Format "yyyyMMdd_HHmmss"

    # Create a folder with the current date and time as the name in the example path
    $script:TeamDiscussionDataFolder = Create-FolderInGivenPath -FolderPath $(Create-FolderInUserDocuments -FolderName "IH") -FolderName $currentDateTime

    if ($script:TeamDiscussionDataFolder) {
        PSWriteColor\Write-Color -Text "Team discussion folder was created '$script:TeamDiscussionDataFolder'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Error -Message "Failed to create discussion folder"
    return $false
}
#endregion



#region Loading Experts and Creating Entities
Try {
    # Load the experts data from the JSON file
    $expertsData = Get-Content -Path "experts.json" | ConvertFrom-Json

    # Initialize an empty array to store the entities
    $ExpertEntities = @()

    # Loop through each expert in the data
    foreach ($expert in $expertsData) {
        # Create a new entity for the expert
        $entity = Build-EntityObject -Name $expert.'Expert Type' -Role "Expert" -Description "An expert in $($expert.'Expert Type')" -Skills $expert.Skills -GPTType "azure" -GPTModel "udtgpt35turbo"

        # Add the entity to the entities array
        $ExpertEntities += $entity
    }

    if ($ExpertEntities) {
        PSWriteColor\Write-Color -Text "Entities were created ($($ExpertEntities.count))" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
    }
}
Catch {
    Write-Error -Message "Failed to create entities"
    return $false
}
#endregion

#region Project Folder Creation
$script:ProjectFolderNameJson = Get-FolderNameTopic -Entity $mainEntity -usermessage $usermessage
Write-Verbose ($script:ProjectFolderNameJson | out-string)

$script:ProjectFolderFullNamePath = Create-FolderInGivenPath -FolderPath $script:TeamDiscussionDataFolder -FolderName (($script:ProjectFolderNameJson | ConvertFrom-Json).foldername | out-string)
#$($($script:ProjectFolderNameJson | convertfrom-json).FolderName | out-string)
if ($script:ProjectFolderFullNamePath) {
    PSWriteColor\Write-Color -Text "Project folder was created '$script:ProjectFolderFullNamePath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
}
#endregion

#region Expert Recommendation
Write-Verbose "Get-ExpertRecommendation"
PSWriteColor\Write-Color -Text "Experts recommendation " -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$output = Get-ExpertRecommendation -Entity $mainEntity -usermessage $usermessage -Experts $ExpertEntities -expertcount 1
#$output

Write-Verbose "first response of gpt to the topic:"
Write-Verbose $output

$attempts = 0
$maxAttempts = 5

while ($attempts -lt $maxAttempts -and -not (Test-IsValidJson $output)) {
    Write-Verbose "The provided string is not a valid JSON. Cleaning process..."
    $output = Get-ExpertRecommendation -Entity $mainEntity -usermessage $usermessage -Experts $ExpertEntities -expertcount 1
    #$output
    Write-Verbose "start Extract-JSON"
    #$output = Extract-JSON -inputString $output
    #$output
    if (-not (Test-IsValidJson $output)) {
        Write-Verbose "start CleantojsonLLM"
        $output = CleantojsonLLM -dataString $output -entity $mainEntity
        #$output
    }
    $attempts++
#$attempts -lt $maxAttempts -and  -not (Test-IsValidJson $output)
}

if ($attempts -eq $maxAttempts) {
    PSWriteColor\Write-Color -Text "Maximum attempts reached. No experts recommendation. Exiting." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime 
    return
}
else {
    Write-Verbose "Valid JSON string provided: $output"
}

$expertstojob = $output | ConvertFrom-Json
$expertstojob = $ExpertEntities | Where-Object { $_.Name -in $expertstojob.jobexperts }

if ($expertstojob) {
    PSWriteColor\Write-Color -Text "Experts were choosed by $($mainEntity.Name) ($($expertstojob.Count)): $($expertstojob.Name -join ", ")" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    $script:ProjectGoalFileFulleNamepath = Save-DiscussionResponse -TextContent $output -Folder $script:TeamDiscussionDataFolder -type "ExpertsRecommendation" -ihguid $ihguid
    foreach ($experttojob in $expertstojob) {
        write-Verbose $($experttojob.Name)
    }
PSWriteColor\Write-Color -Text "Experts recommendation finished" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -StartTab 1
}
#endregion Expert Recommendation

#region Define Project Goal
PSWriteColor\Write-Color -Text "Reviewing project goal..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
Write-Verbose "Defining project goal based on user message: $usermessage"
$projectGoal = ""

$Message = @"
You must suggest project goal described as: 
${usermessage}'
Completion response of project goal MUST be as json syntax only. Other elements, like text beside JSON will be penalized. JSON text object syntax to follow:
{
    "ProjectGoal":  ""
}
"@ | out-string

$Message = @"
The user has provided the following initial description of the Project. Review the description carefully and rewrite it in a more structured and detailed format. MUST fill in any missing information necessary to complete the task. Ensure to capture all key objectives, functionalities, constraints, and any other relevant information. The value of the parameter 'ProjectGoal' must be an imperative sentence. MUST present the revised project description in JSON format:
{
    "ProjectName": "",
    "ProjectGoal": "",
    "Description": ""
}

###Project###
$($usermessage.trim())
"@ | out-string

Write-Verbose "Defining project goal, message: '$Message'"
$arguments = @($Message, 500, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
try {
    $projectGoal = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
}
catch {
    Write-Error -Message "Failed to defining project goal"
}
if ($projectGoal) {
    $script:ProjectGoalFileFulleNamepath = Save-DiscussionResponse -TextContent $projectGoal -Folder $script:TeamDiscussionDataFolder -type "ProjectGoal" -ihguid $ihguid 
    if (Test-Path $script:ProjectGoalFileFulleNamepath) {
        PSWriteColor\Write-Color -Text "Reviewed project goal was saved '$script:ProjectGoalFileFulleNamepath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
    PSWriteColor\Write-Color -Text "User goal: " -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
    PSWriteColor\Write-Color -Text $usermessage -Color Blue -BackGroundColor Yellow -LinesBefore 0 -Encoding utf8 
    PSWriteColor\Write-Color -Text "Reviewed goal: " -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
    PSWriteColor\Write-Color -Text ($projectGoal | ConvertFrom-Json).ProjectGoal -Color Blue -BackGroundColor Yellow -LinesBefore 0 -Encoding utf8 
    $usermessageOryginal = $userMessage
    $usermessage = ($projectGoal | ConvertFrom-Json).ProjectGoal
}
else {
    $projectGoal = $userMessage
}
Write-Verbose "Project goal: $projectGoal"
$mainEntity.AddToConversationHistory($Message, $projectGoal)
#endregion Define Project Goal

<#
#region Generate Project Goal
#PSWriteColor\Write-Color -Text "Generate project goal" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
$message = @"
Generate a project plan based on the user's description. Your task is to analyze the provided description and outline the necessary steps to achieve the project objectives. Consider factors such as data gathering, task execution, expert interaction, iteration, and final deliverables. Provide clear and detailed instructions for each step of the plan. MUST fill in any missing information necessary to complete the task. 

User's description: $projectGoal
"@ | out-string

$message = @"
You MUST generate a project plan based on the provided description. Analyze the description and outline the necessary steps to achieve the project objectives. Consider factors such as data gathering, task execution, expert interaction, iteration, and final deliverables. Provide clear and detailed instructions for each step of the plan. Fill in any missing information necessary to complete the task. Answer a question given in a natural, human-like manner. Output the summarized response in JSON format.
{
    "Project Name": ""
    "Description": ""
    "Imperative sentence": ""
    "Project Plan":[
        {
            "Step 1": ""
            "Description": ""
            "Elements": [
                "",
                ...,
                ""
            ]            
        }
    ]
}

User's description: 
$($projectGoal.trim())
"@ | out-string

Write-Verbose $message
$arguments = @($Message, 1000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
$mainEntity.AddToConversationHistory($message, $OrchestratorProjectPlan)
Write-Verbose "OrchestratorProjectPlan: $OrchestratorProjectPlan"
#endregion Generate Project Goal
#>

#region Processing Discussion
PSWriteColor\Write-Color -Text "Running Project" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
$ExpertsDiscussionHistoryArray = @()
foreach ($expertToJob in $expertstojob) {
    PSWriteColor\Write-Color -Text "Processing by $($expertToJob.Name)..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -StartTab 1
    foreach ($discussionStep in $discussionSteps) {
        if ($discussionStep.isRequired) {
            PSWriteColor\Write-Color -Text "Analyzing step $($discussionStep.step): '$($discussionStep.step_name)'..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine -StartTab 2
            write-verbose "Discussion Step: $($discussionStep.step)" 
            write-verbose "Discussion Step name: $($discussionStep.step_name)"

            $PromptToExpert = @"
You act as $($expertToJob.Description). Your task is to do step desribed as: 
$($discussionStep.description) 
for problem: 
$usermessage
"@ | out-string

            if (-not [string]::IsNullOrEmpty($expertToJob.GetConversationHistory().RESPONSE)) {
                $PromptToExpertHistory = @"

###Past Expert Answers###
$($($expertToJob.GetLastNInteractions(1)).Response)

"@
            }

            $PromptToExpert = @"
$($discussionStep.prompt)
$PromptToExpertHistory
###Project### 
$($projectGoal.trim())
"@ | out-string

            $expertreposnse = $mainEntity.SendResource($PromptToExpert, $expertToJob, "PSAOAI", "Invoke-PSAOAICompletion")
            
            if ($expertreposnse) {
                $expertToJob.AddToConversationHistory($PromptToExpert, $expertreposnse)
                Write-Verbose "expertreposnse: $expertreposnse"
            }

            $message = @"
Your task is to compress the detailed project requirements provided by the GPT expert while highlighting key elements and retaining essential information. Make sure the summary is clear and concise. Output the compressed summary in JSON format.

###Expert's response###
$($expertreposnse.trim())
"@ | out-string
            $arguments = @($Message, 1000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)

            if ($OrchestratorSummary) {
                Write-Verbose $message
                $mainEntity.AddToConversationHistory($message, $OrchestratorSummary)
                Write-Verbose "OrchestratorSummary: $OrchestratorSummary"
            }

            $message = @"
###Instruction###
In JSON format, provide me with information about: Given the provided context, generate content that aligns with the user's needs. The content could involve writing code, preparing a structural design, or composing an article. Ensure that the generated content is relevant and coherent based on the given context.
$usermessage

###Information###
$($expertreposnse.trim())
"@ | out-string
            $arguments = @($Message, 1000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
            $OrchestratorVersionobjective = ""

            if ($OrchestratorVersionobjective) { 
                Write-Verbose $message
                Write-Verbose "OrchestratorVersionobjective: $OrchestratorVersionobjective"
                $mainEntity.AddToConversationHistory($message, $OrchestratorVersionobjective)
            }  
        }            
    }
    $ExpertsDiscussionHistoryArray += $expertToJob.GetConversationHistory()
    $expertDiscussionHistoryFullName = (Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $expertToJob.Name) + ".json"
    $expertToJob.SaveConversationHistoryToFile($expertDiscussionHistoryFullName, "JSON")
}
$ExpertsDiscussionHistoryArray | Export-Clixml -Path (Join-Path $script:TeamDiscussionDataFolder "ExpertsDiscussionHistoryArray.xml")
$OrchestratorDiscussionHistoryArray = $mainEntity.GetConversationHistory()

PSWriteColor\Write-Color -Text "Discussion completed" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
#endregion Processing Discussion

#region ProcessFinishing
PSWriteColor\Write-Color -Text "Process finishing..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$Message = @"
After receiving responses from all experts regarding the project's various steps, compile a comprehensive summary with key elements. Summarize the main objectives, functionalities, constraints, and any other significant details gathered from the experts' responses. Ensure that the summary encapsulates the essence of the project and provides a clear understanding of its scope and requirements. Present the summarized information in JSON format, which will serve as the basis for the final delivery of the project.
"@ | out-string

$messageUser = @"
$($ExpertsDiscussionHistoryArray.response)
"@ | out-string

$Message = @"
You are the data coordinator. Your task is to propose the best solution for the Project. In order to choose the best solution, you have information from experts - "Expert information". If this information is not sufficient, you have to fill in the gaps yourself with the necessary data. The answers of the experts are only a guideline for you on how the Project should be built.

###Project###
$usermessage

###Expert information###
"$($OrchestratorDiscussionHistoryArray.response)" 
"@ | out-string

$Message = @"
After receiving responses from all experts regarding the project's various steps, compile a comprehensive summary with key elements. Summarize the main objectives, functionalities, constraints, and any other significant details gathered from the experts' responses. Ensure that the summary encapsulates the essence of the project and provides a clear understanding of its scope and requirements. Present the summarized information in JSON format, which will serve as the basis for the final delivery of the project.

###Project###
$usermessage

###Expert information###
$($ExpertsDiscussionHistoryArray.response)
"@ | out-string

$Message = @"
After receiving responses from all experts regarding the project's various steps, compile a comprehensive summary with key elements. Summarize the main objectives, functionalities, constraints, and any other significant details gathered from the experts' responses. Ensure that the summary encapsulates the essence of the project and provides a clear understanding of its scope and requirements. Present the summarized information in JSON format, which will serve as the basis for the final delivery of the project.
"@ | out-string

$MessageUser = @"
###Project###
$($ExpertsDiscussionHistoryArray.response)
"@ | out-string

#$($OrchestratorDiscussionHistoryArray.response)
#"$($OrchestratorDiscussionHistoryArray.response | convertto-json)" 
#Write-Verbose $message
Write-Verbose $Message
Write-Verbose $MessageUser
#$arguments = @($Message, $messageUser, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
$arguments = @($Message, $messageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4p")
$OrchestratorAnswer = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAIChatCompletion", $arguments, $verbose)
if ($OrchestratorAnswer) {
    $OrchestratorAnswer
    $script:OrchestratorAnswerFileFulleNamepath = Save-DiscussionResponse -TextContent $OrchestratorAnswer -Folder $script:TeamDiscussionDataFolder -type "ProcessFinishing" -ihguid $ihguid 
    if (Test-Path $script:OrchestratorAnswerFileFulleNamepath) {
        PSWriteColor\Write-Color -Text "ProcessFinishing saved to '$script:OrchestratorAnswerFileFulleNamepath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
$mainEntity.AddToConversationHistory($Message, $MessageUser, $OrchestratorAnswer)
#endregion ProcessFinishing


#region Suggesting Prompt
PSWriteColor\Write-Color -Text "Suggesting prompt..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$Message = @"
###Instruction###
You act as Prompt Engineer. Your task is create an advanced GPT prompt text query to execute the Project. You must ensure that all key and necessary elements are included. Response in a natural, human-like manner. Show prompt text query only.
"@ | out-string
$MessageUser = @"
###Project###
$OrchestratorAnswer
"@ | out-string
Write-Verbose $Message
Write-Verbose $MessageUser
$arguments = @($Message, $messageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4p")
$OrchestratorAnswerSugestPrompt = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAIChatCompletion", $arguments, $verbose)

if ($OrchestratorAnswerSugestPrompt) {
    $OrchestratorAnswerSugestPrompt
    $script:OrchestratorAnswerSugestPromptFileFulleNamepath = Save-DiscussionResponse -TextContent $OrchestratorAnswerSugestPrompt -Folder $script:TeamDiscussionDataFolder -type "SuggestingPrompt" -ihguid $ihguid 
    if (Test-Path $script:OrchestratorAnswerSugestPromptFileFulleNamepath) {
        PSWriteColor\Write-Color -Text "SuggestingPrompt saved to '$script:OrchestratorAnswerSugestPromptFileFulleNamepath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
$mainEntity.AddToConversationHistory($Message, $MessageUser, $OrchestratorAnswerSugestPrompt)
#endregion Suggesting Prompt


#region Suggesting Prompt - Process Final Delivery
PSWriteColor\Write-Color -Text "Suggesting prompt - Process final delivery..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$messageSystem = @"
$OrchestratorAnswerSugestPrompt
"@

$MessageUser = @"
$OrchestratorAnswer
"@

Write-Verbose $messageSystem
Write-Verbose $MessageUser

$arguments = @($messageSystem, $MessageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4p")
$OrchestratorSuggestPromptAnswer = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAIChatCompletion", $arguments, $verbose)
if ($OrchestratorSuggestPromptAnswer) {
    $OrchestratorSuggestPromptAnswer
    $script:OrchestratorSuggestPromptAnswerFileFulleNamepath = Save-DiscussionResponse -TextContent $OrchestratorSuggestPromptAnswer -Folder $script:TeamDiscussionDataFolder -type "SuggestingPromptResponse" -ihguid $ihguid 
    if (Test-Path $script:OrchestratorSuggestPromptAnswerFileFulleNamepath) {
        PSWriteColor\Write-Color -Text "Suggesting prompt - Process final delivery saved to '$script:OrchestratorSuggestPromptAnswerFileFulleNamepath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
$mainEntity.AddToConversationHistory($messageSystem, $MessageUser, $OrchestratorSuggestPromptAnswer)
#endregion Suggesting Prompt - Process Final Delivery


#region Final Delivery
PSWriteColor\Write-Color -Text "Final delivery..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$Message = @"
###Instruction###
You are the Computer Code Orchestrator. Your task is to create computer language code as best solution for the Project. In order to choose the best solution, you have information from Project Manager - "PM information". 

###Project###
$usermessage

###PM information###
$($OrchestratorAnswer.trim())
"@ | out-string

$Message = @"
Based on the information provided throughout the project lifecycle, prepare for the final delivery of the project. Incorporate all relevant deliverables, including the finalized code, documentation, release notes, and deployment instructions. Ensure that the deliverables meet the client's expectations and are ready for deployment. Organize the final delivery package in a structured manner and present the details in desired format.
"@ | Out-String

$MessageUser = @"
$($OrchestratorAnswer.trim())
"@ | out-string

# You MUST respond in a natural, human way, with a concise but comprehensive explanation and an example of how to solve the problem.
###Questions###  1. What is the best answer to user's topic? Suggest example will best suit to the problem
#$arguments = @($Message, 4000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
#$OrchestratorAnswerCode = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $verbose)
Write-Verbose $message
Write-Verbose $MessageUser
$arguments = @($Message, $MessageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4p")
#$OrchestratorAnswer = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $verbose)
$OrchestratorAnswerFinal = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAIChatCompletion", $arguments, $verbose)
if ($OrchestratorAnswerFinal) {
    $OrchestratorAnswerFinal
    $script:OrchestratorAnswerFinalFileFulleNamepath = Save-DiscussionResponse -TextContent $OrchestratorAnswerFinal -Folder $script:TeamDiscussionDataFolder -type "FinalDelivery" -ihguid $ihguid 
    if (Test-Path $script:OrchestratorAnswerFinalFileFulleNamepath) {
        PSWriteColor\Write-Color -Text "Final delivery saved to '$script:OrchestratorAnswerFinalFileFulleNamepath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
$mainEntity.AddToConversationHistory($Message, $MessageUser, $OrchestratorAnswerFinal)
#endregion Final Delivery


#region Final Delivery 2
PSWriteColor\Write-Color -Text "Final delivery 2..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$messagesystem = @"
Given the provided context, you MUST generate content that aligns with the user's needs. The content could involve writing code, preparing a structural design, or composing an article. Ensure that the generated content is relevant and coherent based on the given context.
"@ | out-string

$messageuser = @"
$($OrchestratorAnswer.trim())
"@ | out-string

Write-Verbose $messagesystem
Write-Verbose $messageuser
#$arguments = @($Message, $messageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4")
$arguments = @($messagesystem, $messageuser, "Precise", $true, $true, $mainEntity.name, "udtgpt4p")
$OrchestratorAnswerFinal2 = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAIChatCompletion", $arguments, $verbose)
if ($OrchestratorAnswerFinal2) {
    $OrchestratorAnswerFinal2
    $script:OrchestratorAnswerFinal2FileFulleNamepath = Save-DiscussionResponse -TextContent $OrchestratorAnswerFinal2 -Folder $script:TeamDiscussionDataFolder -type "FinalDelivery2" -ihguid $ihguid 
    if (Test-Path $script:OrchestratorAnswerFinal2FileFulleNamepath) {
        PSWriteColor\Write-Color -Text "Final delivery 2 saved to '$script:OrchestratorAnswerFinal2FileFulleNamepath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
$mainEntity.AddToConversationHistory($messagesystem, $messageuser, $OrchestratorAnswerFinal2)
#endregion Final Delivery 2

#region Summarize and Combine
PSWriteColor\Write-Color -Text "Summarize and Combine..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$messagesystem = @"
You have two different summaries about topic. You MUST combine them into a single, comprehensive summary that incorporates the key points from both.
"@ | out-string

$messageuser = @"

###Summary 1###
$($OrchestratorSuggestPromptAnswer.trim())

###Summary 2###
$($OrchestratorAnswerFinal2.trim())
"@ | out-string

Write-Verbose $messagesystem
Write-Verbose $messageuser
#$arguments = @($Message, $messageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4")
$arguments = @($messagesystem, $messageuser, "Precise", $true, $true, $mainEntity.name, "udtgpt4p")
$OrchestratorAnswerSummarizeAndCombine = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAIChatCompletion", $arguments, $verbose)
if ($OrchestratorAnswerSummarizeAndCombine) {
    $OrchestratorAnswerSummarizeAndCombine
    $script:OrchestratorAnswerSummarizeAndCombineFileFulleNamepath = Save-DiscussionResponse -TextContent $OrchestratorAnswerSummarizeAndCombine -Folder $script:TeamDiscussionDataFolder -type "SummarizeAndCombine" -ihguid $ihguid 
    if (Test-Path $script:OrchestratorAnswerSummarizeAndCombineFileFulleNamepath) {
        PSWriteColor\Write-Color -Text "Summarize And Combine saved to '$script:OrchestratorAnswerSummarizeAndCombineFileFulleNamepath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
$mainEntity.AddToConversationHistory($messagesystem, $messageuser, $OrchestratorAnswerSummarizeAndCombine)
#endregion Summarize and Combine

#region Structured Response
PSWriteColor\Write-Color -Text "Structured Response..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$messagesystem = @"
Based on the following information about topic, You MUST create a response that includes sections that aligns with the user's needs.
"@ | out-string

$messageuser = @"

###Information 1###
$($OrchestratorSuggestPromptAnswer.trim())

###Unformation 2###
$($OrchestratorAnswerFinal2.trim())
"@ | out-string

Write-Verbose $messagesystem
Write-Verbose $messageuser
#$arguments = @($Message, $messageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4")
$arguments = @($messagesystem, $messageuser, "Precise", $true, $true, $mainEntity.name, "udtgpt4p")
$OrchestratorAnswerStructuredResponse = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAIChatCompletion", $arguments, $verbose)
if ($OrchestratorAnswerStructuredResponse) {
    $OrchestratorAnswerStructuredResponse
    $script:OrchestratorAnswerStructuredResponseFileFulleNamepath = Save-DiscussionResponse -TextContent $OrchestratorAnswerStructuredResponse -Folder $script:TeamDiscussionDataFolder -type "StructuredResponse" -ihguid $ihguid 
    if (Test-Path $script:OrchestratorAnswerStructuredResponseFileFulleNamepath) {
        PSWriteColor\Write-Color -Text "Structured Response saved to '$script:OrchestratorAnswerStructuredResponseFileFulleNamepath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }

}
$mainEntity.AddToConversationHistory($messagesystem, $messageuser, $OrchestratorAnswerStructuredResponse)
#endregion Structured Response




#region Save Conversation History
$OrchestratorDiscussionHistoryFullName = (Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $mainEntity.Name) + ".json"
$mainEntity.SaveConversationHistoryToFile($OrchestratorDiscussionHistoryFullName, "JSON")
#endregion Save Conversation History


#region Set Environment Variable
[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "1", "User")
#endregion