[CmdletBinding()]
param(
    [string]$usermessage,
    [int]$expertCount = 3
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
$experts = Get-ExpertsFromJson -FilePath "experts.json"
if ($experts) {
    PSWriteColor\Write-Color -Text "Imported experts data ($($experts.count))" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
}
#endregion

#region Importing Discussion Steps

$discussionSteps = Get-DiscussionStepsFromJson -FilePath "discussion_steps6.json"
if ($discussionSteps) {
    PSWriteColor\Write-Color -Text "Discussion steps was loaded ($($discussionSteps.count))" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
}
#endregion

#region Creating Main Entity
$mainEntity = Build-EntityObject -Name "Orchestrator" -Role "Project Manager" -Description "Manager of experts" -Skills @("Organization", "Communication", "Problem-Solving") -GPTType "azure" -GPTModel "udtgpt35turbo"
if ($mainEntity) {
    PSWriteColor\Write-Color -Text "Main Entity was created" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
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
#endregion Creating Team Discussion Folder

#region Loading Experts and Creating Entities
Try {
    # Load the experts data from the JSON file
    $expertsData = Get-Content -Path "experts.json" -Raw | ConvertFrom-Json
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
$script:ProjectFolderNameJson
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
$output = Get-ExpertRecommendation -Entity $mainEntity -usermessage $usermessage -Experts $ExpertEntities -expertcount $expertCount
#write-Host $output
Write-Verbose "first response of gpt to the topic:"
Write-Verbose $output
$attempts = 0
$maxAttempts = 5
while ($attempts -lt $maxAttempts -and -not (Test-IsValidJson $output)) {
    Write-Verbose "The provided string is not a valid JSON. Cleaning process..."
    PSWriteColor\Write-Color -Text "Data pre-processing " -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine -StartTab 1
    #$output = Get-ExpertRecommendation -Entity $mainEntity -usermessage $usermessage -Experts $ExpertEntities -expertcount 2
    #Write-Host $output
    #Write-Verbose "start Extract-JSON"
    #$output = Extract-JSON -inputString $output
    #$output
    Write-Verbose "start CleantojsonLLM"
    $output = CleantojsonLLM -dataString $output -entity $mainEntity
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

#region Define Project Explorations
PSWriteColor\Write-Color -Text "Project exploration" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
Write-Verbose "Defining project based on user message: $usermessage"
$projectGoal = ""

$Message = @"
You must suggest project goal described as: 
${usermessage}
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

$Message = @"
$($discussionSteps[0].prompt)

Show only JSON object

###Project### 
$($usermessage.trim())
"@
#Write-Host $Message
Write-Verbose "Defining project goal, message: '$Message'"
$arguments = @($Message, 1000, "UltraPrecise", $mainEntity.name, $mainEntity.GPTModel, $true)
try {
    $projectGoal = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
    #write-Host $projectGoal
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
    PSWriteColor\Write-Color -Text $(($projectGoal | ConvertFrom-Json).ProjectGoal) -Color Blue -BackGroundColor Yellow -LinesBefore 0 -Encoding utf8 
    $usermessageOryginal = $userMessage
    $usermessage = ($projectGoal | ConvertFrom-Json).ProjectGoal
}
else {
    $projectGoal = $userMessage
}
Write-Verbose "Project goal: $projectGoal"
$mainEntity.AddToConversationHistory($Message, $projectGoal)
#endregion Define Project Explorations

#region Draft project output
PSWriteColor\Write-Color -Text "Draft prompt" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$Message = @"
You as Prompt Engineer have task to create an GPT prompt text query to execute the Project expected output. Focus on ProjectGoal. Ensure that all key and necessary elements are included. Response in a natural, human-like manner, and show prompt text query only.

###Project###
$projectGoal
"@ | out-string

$Message = @"
### Instruction
Create a GPT prompt text query for the project's expected output, focusing on the project goal. Ensure all key elements are included. Answer in a natural, human-like manner. Provide the prompt text query only. A prompt must comply with the following principles:
1. Avoid unnecessary politeness in prompts to maintain conciseness.
2. Integrate the intended audience's expertise level into the prompt.
3. Break down complex tasks into a sequence of simpler prompts for clarity.
4. Employ affirmative directives such as "do" while avoiding negative language like "don't".
5. Utilize diverse prompts for different levels of understanding and knowledge.
6. Incorporate a tipping mechanism for motivation when necessary.
7. Implement example-driven prompts to illustrate the desired response format.
8. Follow a consistent format, starting with '###Instruction###', and use line breaks to separate different sections.
9. Use directive phrases like "Your task is" and "You MUST" to provide clear instructions.
10. Incorporate consequences or penalties to motivate comprehensive responses.
11. Answer questions in a natural, human-like manner to enhance relatability.
12. Use leading words for clear guidance in problem-solving prompts.
13. Ensure responses are unbiased and avoid relying on stereotypes.
14. Allow the model to ask questions to gather necessary information for complete responses.
15. Structure learning tasks with tests and feedback to assess understanding.
16. Assign a role to the LLM to frame the context of the response.
17. Use delimiters to set context and guide essay-type responses.
18. Repeat key terms for emphasis and clarity within the prompt.
19. Combine Chain-of-Thought with Few-Shot prompts to enhance reasoning.
20. Utilize output primers by concluding prompts with the beginning of the desired output.
21. Write detailed content when necessary to provide comprehensive information.
22. Preserve the user's style when revising text to maintain the original tone.
23. Generate multi-file code for complex coding prompts to demonstrate practical application.
24. Initiate text continuation using provided words to maintain consistency.
25. Clearly state the requirements that the model must follow using keywords for content generation.
26. Mimic provided language style in the prompt to match a given sample.
27. In the prompt, "you" must refer to the LLM model and "I" to the user.
For example, when assessing Principle 7 (example-driven prompts), you might say:
"The user prompt lacks concrete examples to guide the LLM's response. For instance, if the prompt asks for an explanation of photosynthesis, it should include a simple example like 'Explain how a plant makes its food from sunlight.'"
Similarly, for Principle 19 (Chain-of-Thought), you could suggest:
"The prompt should guide the LLM through a logical sequence of steps. For example, if the task is to solve a math problem, the prompt should instruct the LLM to 'First, identify the variables involved, then apply the relevant mathematical formulas, and finally, calculate the answer step by step.'"

### Project
$($projectGoal.trim())
"@
$arguments = @($Message, 2000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
$projectDraftPrompt = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
if ($projectDraftPrompt) {
    Write-Host $projectDraftPrompt
    $script:projectDraftPromptFileFulleNamepath = Save-DiscussionResponse -TextContent $projectDraftPrompt -Folder $script:TeamDiscussionDataFolder -type "projectDraftPrompt" -ihguid $ihguid 
    if (Test-Path $script:projectDraftPromptFileFulleNamepath) {
        PSWriteColor\Write-Color -Text "Project draft saved to '$script:projectDraftPromptFileFulleNamepath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
} else {
    Write-Warning "Empty Prototype Prompt. Exiting"
    return $false
}

$Message = @"
$($projectDraftPrompt.trim())

###Project###
$($projectGoal.trim() | ConvertFrom-Json | select * | out-string)
"@ | out-string
PSWriteColor\Write-Color -Text "Prototype" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$arguments = @($Message, 1000, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
$projectDraft = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
if ($projectDraft) {
    Write-Host $projectDraft
    $script:projectDraftFileFulleNamepath = Save-DiscussionResponse -TextContent $projectDraft -Folder $script:TeamDiscussionDataFolder -type "projectDraft" -ihguid $ihguid 
    if (Test-Path $script:projectDraftFileFulleNamepath) {
        PSWriteColor\Write-Color -Text "Project draft saved to '$script:projectDraftFileFulleNamepath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
} else {
    Write-Warning "Empty Prototype. Exiting"
    return $false
}

#endregion Draft project output

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
        if ($discussionStep.isRequired -and $discussionStep.step -gt 1) {
            PSWriteColor\Write-Color -Text "Analyzing step: '$($discussionStep.step_name)'..." -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine -StartTab 2
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

###Project### 
$($projectGoal.trim())

###Project output draft###
$($projectDraft.trim())
"@ | out-string
            #$PromptToExpertHistory
            #$PromptToExpert
            $expertreposnse = $mainEntity.SendResource($PromptToExpert, $expertToJob, "PSAOAI", "Invoke-PSAOAICompletion")
            

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
You MUST compile a comprehensive summary with key elements after receiving responses from all experts regarding the project's various steps. Summarize the main objectives, functionalities, constraints, and any other significant details gathered from the experts' responses. Ensure that the summary encapsulates the essence of the project and provides a clear understanding of its scope and requirements. Present the summarized information in JSON format, which will serve as the basis for the final delivery of the project.
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
You MUST compile a comprehensive summary with key elements after receiving responses from all experts regarding the project's various steps. Summarize the main objectives, functionalities, constraints, and any other significant details gathered from the experts' responses. Ensure that the summary encapsulates the essence of the project and provides a clear understanding of its scope and requirements. Present the summarized information in JSON format, which will serve as the basis for the final delivery of the project.
"@ | out-string
#You MUST ensure that response is based on verified sources.
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
    #$OrchestratorAnswer
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
You act as Prompt Engineer. Your task is create an advanced GPT prompt text query to execute the Project expected output. You must ensure that all key and necessary elements are included. Response in a natural, human-like manner. Show prompt text query only.
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
    #$OrchestratorAnswerSugestPrompt
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
    #$OrchestratorAnswerFinal
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
    #$OrchestratorAnswerFinal2
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
    #$OrchestratorAnswerSummarizeAndCombine
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
    #$OrchestratorAnswerStructuredResponse
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