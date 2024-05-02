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
    $discussionSteps = Get-DiscussionStepsFromJson -FilePath "discussion_steps4.json"

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
"@

$Message = @"
The user has provided the following initial description of the Project. Review the description carefully and rewrite it in a more structured and detailed format. MUST fill in any missing information necessary to complete the task. Ensure to capture all key objectives, functionalities, constraints, and any other relevant information. The value of the parameter 'ProjectGoal' must be an imperative sentence. Present the revised project description in JSON format.
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
"@

Write-Verbose "Defining project goal, message: '$Message'"
$arguments = @($Message, 500, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
try {
    $projectGoal = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
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

Write-Verbose "Project goal: $projectGoal"
#endregion

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
"@

            $PromptToExpert = @"
You act as $($expertToJob.Description). Your task is to do step desribed as: 
$($discussionStep.description) 
for problemg: 
$usermessage
"@

            $PromptToExpert = @"
###Instrunction###
$($discussionStep.prompt)
The user provided the following initial description:
$usermessage

###Past Expert Answers###
$($($expertToJob.GetConversationHistory()).Response)
"@

            #You MUST answer in a natural, human-like manner, providing a concise yet comprehensive explanation.
            $expertreposnse = $mainEntity.SendResource($PromptToExpert, $expertToJob, "PSAOAI", "Invoke-PSAOAICompletion")
            $expertToJob.AddToConversationHistory($PromptToExpert, $expertreposnse)
            Write-Verbose "expertreposnse: $expertreposnse"

            # summary of expert response by Orchestrator
            PSWriteColor\Write-Color -Text "Process expert response..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -StartTab 1 -NoNewLine
            $message = @"
Summary and get key points for text:
$($expertreposnse.trim())
"@

            $message = @"
Summarize the provided response, encapsulating the main points, objectives, functionalities, constraints, and any other pertinent details. Ensure clarity and conciseness in the summary, presenting the essential information in a structured format. Output the summarized response in JSON format.

###Response###
$($expertreposnse.trim())
"@

$message = @"
Your task is to compress the detailed project requirements provided by the GPT expert while highlighting key elements and retaining essential information. Make sure the summary is clear and concise. Output the compressed summary in JSON format.

###Expert's response###
$($expertreposnse.trim())
"@

            Write-Verbose $message
            $arguments = @($Message, 800, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
            $OrchestratorSummary = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
            $mainEntity.AddToConversationHistory($message, $OrchestratorSummary)
            Write-Verbose "OrchestratorSummary: $OrchestratorSummary"


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
"@

$Message = @"
After receiving responses from all experts regarding the project's various steps, compile a comprehensive summary with key elements. Summarize the main objectives, functionalities, constraints, and any other significant details gathered from the experts' responses. Ensure that the summary encapsulates the essence of the project and provides a clear understanding of its scope and requirements. Present the summarized information in JSON format, which will serve as the basis for the final delivery of the project.

###Project###
$usermessage

###Expert information###
$($OrchestratorDiscussionHistoryArray.response)
"@
#"$($OrchestratorDiscussionHistoryArray.response | convertto-json)" 
Write-Verbose $message
$arguments = @($Message, 1000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
$OrchestratorAnswer = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $verbose)
$OrchestratorAnswer
$mainEntity.AddToConversationHistory($Message, $OrchestratorAnswer)

PSWriteColor\Write-Color -Text "CC Process finishing..." -Color Blue -BackGroundColor DarkCyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$Message = @"
After receiving responses from all experts regarding the project's various steps, compile a comprehensive summary with key elements. Summarize the main objectives, functionalities, constraints, and any other significant details gathered from the experts' responses. Ensure that the summary encapsulates the essence of the project and provides a clear understanding of its scope and requirements. Present the summarized information in JSON format, which will serve as the basis for the final delivery of the project.
"@

$messageUser = @"
$($OrchestratorDiscussionHistoryArray.response)
"@

Write-Verbose $message
Write-Verbose $messageUser
$arguments = @($Message, $messageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4")
$OrchestratorAnswer = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAIChatCompletion", $arguments, $verbose)
$OrchestratorAnswer
$mainEntity.AddToConversationHistory($Message, $OrchestratorAnswer)


PSWriteColor\Write-Color -Text "Suggesting prompt..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
$Message = "Please provide an advanced prompt to execute the project, ensuring all necessary elements are included. $OrchestratorAnswer"
Write-Verbose $message
$arguments = @($Message, 1000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
$OrchestratorAnswerSugestPrompt = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $verbose)
$OrchestratorAnswerSugestPrompt
$mainEntity.AddToConversationHistory($Message, $OrchestratorAnswerSugestPrompt)

PSWriteColor\Write-Color -Text "Suggesting prompt - Process final delivery..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
$messageUser = @"
$($OrchestratorDiscussionHistoryArray.response)
"@

Write-Verbose $OrchestratorAnswerSugestPrompt
Write-Verbose $OrchestratorAnswer
#$arguments = @($Message, $messageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4")
$arguments = @($Message, $messageUser, "Precise", $true, $true, $mainEntity.name, "udtgpt4")
$OrchestratorAnswer = $mainEntity.InvokeChatCompletion("PSAOAI", "Invoke-PSAOAIChatCompletion", $arguments, $verbose)
$OrchestratorAnswer
$mainEntity.AddToConversationHistory($OrchestratorAnswerSugestPrompt, $OrchestratorAnswer)



PSWriteColor\Write-Color -Text "Process final delivery..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
$Message = @"
###Instruction###
You are the Computer Code Orchestrator. Your task is to create computer language code as best solution for the Project. In order to choose the best solution, you have information from Project Manager - "PM information". 

###Project###
$usermessage

###PM information###
$($OrchestratorAnswer.trim())
"@

$Message = @"
Based on the information provided throughout the project lifecycle, prepare for the final delivery of the project. Incorporate all relevant deliverables, including the finalized code, documentation, release notes, and deployment instructions. Ensure that the deliverables meet the client's expectations and are ready for deployment. Organize the final delivery package in a structured manner and present the details in desired format.

###Information###
$($OrchestratorAnswer.trim())
"@

# You MUST respond in a natural, human way, with a concise but comprehensive explanation and an example of how to solve the problem.
###Questions###  1. What is the best answer to user's topic? Suggest example will best suit to the problem
Write-Verbose $message
$arguments = @($Message, 1000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
$OrchestratorAnswerCode = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $verbose)
$OrchestratorAnswerCode
$mainEntity.AddToConversationHistory($Message, $OrchestratorAnswerCode)


$OrchestratorDiscussionHistoryFullName = (Join-Path -Path $script:TeamDiscussionDataFolder -ChildPath $mainEntity.Name) + ".json"
$mainEntity.SaveConversationHistoryToFile($OrchestratorDiscussionHistoryFullName, "JSON")

#region Set Environment Variable
[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "1", "User")
#endregion