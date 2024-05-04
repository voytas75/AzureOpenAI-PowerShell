[CmdletBinding()]
param(
    $usermessage
)

# Define PowerShell class for Entity

# Import PSaoAI module
[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "0", "User")
#Import-Module -Name PSaoAI
Import-module "D:\dane\voytas\Dokumenty\visual_studio_code\github\AzureOpenAI-PowerShell\PSAOAI\PSAOAI.psd1" -Force 
import-module PSWriteColor

$IHGUID = [System.Guid]::NewGuid().ToString()


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

Try {
    $discussionSteps = Get-DiscussionStepsFromJson -FilePath "discussion_steps5.json"

    if ($discussionSteps) {
        PSWriteColor\Write-Color -Text "Discussion steps was loaded ($($discussionSteps.count))" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Error -Message "Failed to loade discussion steps"
    return $false
}

Try {
    $mainEntity = Build-EntityObject -Name "Orchestrator" -Role "Project Manager" -Description "Manager of experts" -Skills @("Organization", "Communication", "Problem-Solving") -GPTType "azure" -GPTModel "udtgpt35turbo"

    if ($mainEntity) {
        PSWriteColor\Write-Color -Text "Main Entity was created" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Error -Message "Failed to create Main Entity"
    return $false
}

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
        PSWriteColor\Write-Color -Text "Entities were created ($($ExpertEntities.count))" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Error -Message "Failed to create entities"
    return $false
}


#region Project Folder Creation
$script:ProjectFolderNameJson = Get-FolderNameTopic -Entity $mainEntity -usermessage $usermessage
Write-Verbose ($script:ProjectFolderNameJson | out-string)

$script:ProjectFolderFullNamePath = Create-FolderInGivenPath -FolderPath $script:TeamDiscussionDataFolder -FolderName (($script:ProjectFolderNameJson | ConvertFrom-Json).foldername | out-string)
#$($($script:ProjectFolderNameJson | convertfrom-json).FolderName | out-string)
if ($script:ProjectFolderFullNamePath) {
    PSWriteColor\Write-Color -Text "Project folder was created '$script:ProjectFolderFullNamePath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
}
#endregion

#return 

#region Expert Recommendation
Write-Verbose "Get-ExpertRecommendation"
$output = Get-ExpertRecommendation -Entity $mainEntity -usermessage $usermessage -Experts $ExpertEntities

if ($output) {
    PSWriteColor\Write-Color -Text "Experts recommendation finished" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
} 

Write-Verbose "first response of gpt to the topic:"
Write-Verbose $output

$attempts = 0
$maxAttempts = 5

while ($attempts -lt $maxAttempts -and -not (Test-IsValidJson $output)) {
    Write-Verbose "The provided string is not a valid JSON. Cleaning process..."

    Write-Verbose "start Extract-JSON"
    $output = Extract-JSON -inputString $output

    #$output.gettype()

    #$output[0]

    if (-not (Test-IsValidJson $output)) {
        <# Action to perform if the condition is true #>
    
        Write-Verbose "start CleantojsonLLM"
        $output = CleantojsonLLM -dataString $output -entity $mainEntity
    
        Write-Host $output

    }
    $attempts++
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
    $script:ProjectGoalFileFulleNamepath = Save-DiscussionResponse -TextContent $output -Folder $script:ProjectFolderFullNamePath -type "ExpertsRecommendation" -ihguid $ihguid
    foreach ($experttojob in $expertstojob) {
        write-Verbose $($experttojob.Name)
    }
}
#endregion

#region Define Project Goal
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
    "Objectives": [
        "",
        ...
        ""
    ],
    "Functionalities": [
        "",
        ...
        ""
    ],
    "Constraints": [
        "",
        ...
        ""
    ],
    "OtherInformation": [
        "",
        ...
        ""
    ]
}

###Project###
${usermessage}
"@ | out-string

Write-Verbose "Defining project goal, message: '$Message'"
$arguments = @($Message, 500, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
try {
    #$projectGoal = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
}
catch {
    Write-Error -Message "Failed to defining project goal"
}
if ($projectGoal) {
    $mainEntity.AddToConversationHistory($Message, $projectGoal)

    $script:ProjectGoalFileFulleNamepath = Save-DiscussionResponse -TextContent $projectGoal -Folder $script:ProjectFolderFullNamePath -type "ProjectGoal" -ihguid $ihguid 
    if (Test-Path $script:ProjectGoalFileFulleNamepath) {
        PSWriteColor\Write-Color -Text "Project goal was definied '$script:ProjectGoalFileFulleNamepath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
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


#endregion

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

#$projectGoal

Write-Verbose $message
$arguments = @($Message, 800, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
#$OrchestratorProjectPlan = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
$mainEntity.AddToConversationHistory($message, $OrchestratorProjectPlan)
Write-Verbose "OrchestratorProjectPlan: $OrchestratorProjectPlan"

#return

PSWriteColor\Write-Color -Text "Processing discussion..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
$ExpertsDiscussionHistoryArray = @()
foreach ($expertToJob in $expertstojob) {
    PSWriteColor\Write-Color -Text "Processing by $($expertToJob.Name)..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -StartTab 1
    foreach ($discussionStep in $discussionSteps) {
        if ($discussionStep.isRequired) {
            PSWriteColor\Write-Color -Text "Analyzing step: '$($discussionStep.step_name)'..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine -StartTab 1
            write-verbose "Discussion Step: $($discussionStep.step)" 
            write-verbose "Discussion Step name: $($discussionStep.step_name)"

            #Get-LLMResponse -usermessage $usermessage -entity $mainEntity -expert $expertToJob -goal $projectGoal -title $discussionStep.title -description $discussionStep.description -importance $discussionStep.importance -steps ($discussionStep.steps -join "`n") -examples $discussionStep.examples
            # Ask each entity to provide its perspective
            $PromptToExpert = @"
Prepare you point of view in area: $($discussionStep.description), for project description: "$usermessage"
You MUST answer in a natural, human-like manner, providing a concise yet comprehensive explanation.
"@ | out-string

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
                #$($($expertToJob.GetConversationHistory()).Response)
            }


            $PromptToExpert = @"
$($discussionStep.prompt)
$PromptToExpertHistory
###Project### 
$($projectGoal.trim())
"@ | out-string

            #$PromptToExpert
            #You MUST answer in a natural, human-like manner, providing a concise yet comprehensive explanation.
            $expertreposnse = ""
            $expertreposnse = $mainEntity.SendResource($PromptToExpert, $expertToJob, "PSAOAI", "Invoke-PSAOAIChatCompletion")
            if ($expertreposnse) {
                $expertreposnse 
                $expertToJob.AddToConversationHistory($PromptToExpert, $expertreposnse)
                Write-Verbose "expertreposnse: $expertreposnse"
            }

            # summary of expert response by Orchestrator
            #PSWriteColor\Write-Color -Text "Process expert response..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -StartTab 1 -NoNewLine
            $message = @"
Summary and get key points for text:
$($expertreposnse.trim())
"@ | out-string

            $message = @"
Summarize the provided response, encapsulating the main points, objectives, functionalities, constraints, and any other pertinent details. Ensure clarity and conciseness in the summary, presenting the essential information in a structured format. Output the summarized response in JSON format.

###Response###
$($expertreposnse.trim())
"@ | out-string

            $message = @"
Your task is to compress the detailed project requirements provided by the GPT expert while highlighting key elements and retaining essential information. Make sure the summary is clear and concise. Output the compressed summary in JSON format.

###Expert's response###
$($expertreposnse.trim())
"@ | out-string
            $arguments = @($Message, 2000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
            #$OrchestratorSummary = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
            if ($OrchestratorSummary) {
                Write-Verbose $message
                #Write-Host $Message
                $OrchestratorSummary
                $mainEntity.AddToConversationHistory($message, $OrchestratorSummary)
                Write-Verbose "OrchestratorSummary: $OrchestratorSummary"
            }

            #PSWriteColor\Write-Color -Text "generate version of user's project goal" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -StartTab 1 -NoNewLine
            $message = @"
###Instruction###
In JSON format, provide me with information about: Given the provided context, generate content that aligns with the user's needs. The content could involve writing code, preparing a structural design, or composing an article. Ensure that the generated content is relevant and coherent based on the given context.
$usermessage

###Information###
$($expertreposnse.trim())
"@ | out-string
            #Write-Host $Message
            $arguments = @($Message, 2000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
            $OrchestratorVersionobjective = ""
            #$OrchestratorVersionobjective = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
            if ($OrchestratorVersionobjective) { 
                Write-Verbose $message
                $OrchestratorVersionobjective
                #Write-Host $message
                Write-Verbose "OrchestratorVersionobjective: $OrchestratorVersionobjective"
                $mainEntity.AddToConversationHistory($message, $OrchestratorVersionobjective)
            }  
            Start-Sleep -Seconds 3
        }            
    }
    $ExpertsDiscussionHistoryArray += $expertToJob.GetConversationHistory()
    $expertDiscussionHistoryFullName = (Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $expertToJob.Name) + ".json"
    $expertToJob.SaveConversationHistoryToFile($expertDiscussionHistoryFullName, "JSON")
}
$ExpertsDiscussionHistoryArray | Export-Clixml -Path (Join-Path $script:TeamDiscussionDataFolder "ExpertsDiscussionHistoryArray.xml")
$OrchestratorDiscussionHistoryArray = $mainEntity.GetConversationHistory()


PSWriteColor\Write-Color -Text "Discussion completed" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime

PSWriteColor\Write-Color -Text "Process finishing..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$Message = @"
You are the data coordinator. Your task is to propose the best solution for the Project. In order to choose the best solution, you have information from experts - "Expert information". If this information is not sufficient, you have to fill in the gaps yourself with the necessary data. The answers of the experts are only a guideline for you on how the Project should be built.

###Project###
$usermessage

###Expert information###
"$($OrchestratorDiscussionHistoryArray.response | convertto-json)" 
"@ | out-string

$Message = @"
After receiving responses from all experts regarding the project's various steps, compile a comprehensive summary with key elements. Summarize the main objectives, functionalities, constraints, and any other significant details gathered from the experts' responses. Ensure that the summary encapsulates the essence of the project and provides a clear understanding of its scope and requirements. Present the summarized information in JSON format, which will serve as the basis for the final delivery of the project.

###Project###
$usermessage

###Expert information###
$($ExpertsDiscussionHistoryArray.response)

"@ | out-string
#$($OrchestratorDiscussionHistoryArray.response)
#"$($OrchestratorDiscussionHistoryArray.response | convertto-json)" 
Write-Verbose $message
$OrchestratorAnswer = ""
$arguments = @($Message, 1000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
$OrchestratorAnswer = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $verbose)
if ($OrchestratorAnswer) {
    $OrchestratorAnswer
    $mainEntity.AddToConversationHistory($Message, $OrchestratorAnswer)
}


PSWriteColor\Write-Color -Text "CC Process finishing..." -Color Blue -BackGroundColor DarkCyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$Message = @"
After receiving responses from all experts regarding the project's various steps, compile a comprehensive summary with key elements. Summarize the main objectives, functionalities, constraints, and any other significant details gathered from the experts' responses. Ensure that the summary encapsulates the essence of the project and provides a clear understanding of its scope and requirements. Present the summarized information in JSON format, which will serve as the basis for the final delivery of the project.
"@ | out-string

$messageUser = @"
$($ExpertsDiscussionHistoryArray.response)
"@ | out-string

Write-Verbose $message
Write-Verbose $messageUser
$OrchestratorAnswer = ""
$arguments = @($Message, $messageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4")
$OrchestratorAnswer = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAIChatCompletion", $arguments, $verbose)
if ($OrchestratorAnswer) {
    $OrchestratorAnswer
    $mainEntity.AddToConversationHistory($Message, $OrchestratorAnswer)
}


PSWriteColor\Write-Color -Text "Suggesting prompt..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
$Message = "Please provide an advanced prompt to execute the project, ensuring all necessary elements are included. $OrchestratorAnswer" | out-string
Write-Verbose $message
$arguments = @($Message, 1000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
$OrchestratorAnswerSugestPrompt = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $verbose)
if ($OrchestratorAnswerSugestPrompt) {
    $OrchestratorAnswerSugestPrompt
    $mainEntity.AddToConversationHistory($Message, $OrchestratorAnswerSugestPrompt)
}


PSWriteColor\Write-Color -Text "Suggesting prompt - Process final delivery..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
$messageUser = @"
$($OrchestratorDiscussionHistoryArray.response)
"@

Write-Verbose $OrchestratorAnswerSugestPrompt
Write-Verbose $OrchestratorAnswer
$arguments = @($OrchestratorAnswerSugestPrompt, 2000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
#$arguments = @($OrchestratorAnswerSugestPrompt, $messageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4")
$OrchestratorAnswer = ""
$OrchestratorAnswer = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $verbose)
#$OrchestratorAnswer = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAIChatCompletion", $arguments, $verbose)
#$OrchestratorAnswer = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $verbose)
if ($OrchestratorAnswer) {
    $OrchestratorAnswer
    $mainEntity.AddToConversationHistory($OrchestratorAnswerSugestPrompt, $OrchestratorAnswer)
}

PSWriteColor\Write-Color -Text "Process final delivery..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
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

###Information###
$($OrchestratorAnswer.trim())
"@ | out-string

# You MUST respond in a natural, human way, with a concise but comprehensive explanation and an example of how to solve the problem.
###Questions###  1. What is the best answer to user's topic? Suggest example will best suit to the problem
Write-Verbose $message
$arguments = @($Message, 1000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
$OrchestratorAnswerCode = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $verbose)
$OrchestratorAnswerCode
$mainEntity.AddToConversationHistory($Message, $OrchestratorAnswerCode)


$messagesystem = @"
Given the provided context, you MUST generate content that aligns with the user's needs. The content could involve writing code, preparing a structural design, or composing an article. Ensure that the generated content is relevant and coherent based on the given context.
"@ | out-string

$messageuser = @"
$OrchestratorAnswerCode
"@ | out-string

Write-Verbose $messagesystem
Write-Verbose $messageuser
#$arguments = @($Message, $messageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4")
$arguments = @($messagesystem, $messageuser, "Precise", $true, $true, $mainEntity.name, "udtgpt4")
$OrchestratorAnswer = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAIChatCompletion", $arguments, $verbose)
$OrchestratorAnswer
$mainEntity.AddToConversationHistory($OrchestratorAnswerSugestPrompt, $OrchestratorAnswer)

$OrchestratorDiscussionHistoryFullName = (Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $mainEntity.Name) + ".json"
$mainEntity.SaveConversationHistoryToFile($OrchestratorDiscussionHistoryFullName, "JSON")

#region Set Environment Variable
[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "1", "User")
#endregion