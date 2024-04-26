param(
    $usermessage
)

# Define PowerShell class for Entity

# Import PSaoAI module
[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "0", "User")
#Import-Module -Name PSaoAI
Import-module "D:\dane\voytas\Dokumenty\visual_studio_code\github\AzureOpenAI-PowerShell\PSAOAI\PSAOAI.psd1" -Force 

import-module PSWriteColor

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
    $discussionSteps = ReadDiscussionStepsFromJson -FilePath "discussion_steps3.json"

    if ($discussionSteps) {
        PSWriteColor\Write-Color -Text "Discussion steps was loaded ($($discussionSteps.count))" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Error -Message "Failed to loade discussion steps"
    return $false
}

Try {
    $mainEntity = Build-EntityObject -Name "Project Manager" -Role "Project Manager" -Description "Manager of experts" -Skills @("Organization", "Communication", "Problem-Solving") -GPTType "azure" -GPTModel "udtgpt35turbo"

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
    $entities = @()

    # Loop through each expert in the data
    foreach ($expert in $expertsData) {
        # Create a new entity for the expert
        $entity = Build-EntityObject -Name $expert.'Expert Type' -Role "Expert" -Description "An expert in $($expert.'Expert Type')" -Skills $expert.Skills -GPTType "azure" -GPTModel "udtgpt35turbo"

        # Add the entity to the entities array
        $entities += $entity
    }

    if ($entities) {
        PSWriteColor\Write-Color -Text "Entities were created ($($entities.count))" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Error -Message "Failed to create entities"
    return $false
}

<#
if ($entities -eq $null -or $entities.Count -eq 0) {
    Write-Error -Message "No entities found. Please ensure that the entities are properly loaded from the JSON file."
    return $false
}
else {
    Write-Host "Entities loaded successfully. Total entities: $($entities.Count)"
    foreach ($entity in $entities) {
        Write-Host "Entity Name: $($entity.Name)"
        #Write-Host "Entity Role: $($entity.Role)"
        Write-Host "Entity Description: $($entity.Description)"
        #Write-Host "Entity Skills: $($entity.Skills -join ', ')"
        #Write-Host "Entity GPT Type: $($entity.GPTType)"
        #Write-Host "Entity GPT Model: $($entity.GPTModel)"
        Write-Host "----------------------------------------"
    }
}
#>

$responsejson1 = @'
{
    "jobexperts":  [
                      "{Name1}",
                      "{Name2}",
                      "{Name3}"
                   ]
}
'@

$Message = "User need help. The task is '${usermessage}'. Analyze the user's task to choose three of the most useful experts to get the job done. Response must be as test json object with only Name of choosed experts. You must response as JSON:`n$responsejson1`nList of available experts:`n $($entities | convertto-json)`n"

$arguments = @($Message, 800, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
$output = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)


#Write-Color -Text  $output -Color Blue -BackGroundColor DarkYellow

try {
    Write-Color -Text "Function cleaning" -Color Magenta -BackGroundColor DarkGreen
    $output = Clear-LLMDataJSOn $output    
    #Write-Color -Text $output -Color Blue -BackGroundColor DarkYellow
    
}
catch {
    $Message = @"

###Instruction###

You must clean data and leave only JSON text object without block code. If there is no json data create it with structure:

$responsejson1

###Data to clean###

$output
"@
    Write-Color -Text "LLM cleaning" -Color Magenta -BackGroundColor DarkGreen
    $arguments = @($Message, 800, "Precise", $mainEntity.name, $mainEntity.GPTModel, $true)
    $output = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
    
    Write-Color -Text "Function cleaning" -Color Magenta -BackGroundColor DarkGreen
    $output = Clear-LLMDataJSOn $output    
    #Write-Color -Text $output -Color Blue -BackGroundColor DarkYellow
}



#Write-Color -Text $output -Color Blue -BackGroundColor DarkYellow

#$jobexpertsFileFullName = Save-DiscussionResponse -TextContent $output -Folder $script:TeamDiscussionDataFolder


#$expertstojob = Get-Content $jobexpertsFileFullName -Raw | ConvertFrom-Json
$expertstojob = $output | ConvertFrom-Json
$expertstojob = $entities | Where-Object { $_.Name -in $expertstojob.jobexperts }
#$global:entities = $entities
#$expertstojobFileFullName = Save-DiscussionResponse -TextContent $($expertstojob | ConvertTo-Json) -Folder $script:TeamDiscussionDataFolder
if ($expertstojob) {
    PSWriteColor\Write-Color -Text "Experts were choosed by $($mainEntity.Name) ($($mainEntity.Count))" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    foreach ($experttojob in $expertstojob) {
        write-host $($experttojob.Name)
    }
}





#, @("-usermessage", "i am $($mainEntity.Name)", "-MaxTokens", 800, "-mode", "Creative", "-simpleresponse", "-Deployment", $mainEntity.GPTModel, "-APIVersion", "2024-03-01-preview"))
# Use the output as needed



#$functionName = "Invoke-PSAOAICompletion"
#$response = & $functionName @arguments | Out-String
#Write-Color -Text $response.trim() -Color Blue -BackGroundColor DarkYellow









<#
$prompt1 = @"
Expand topic '{0}', and you MUST show it as a JSON object and only JSON. Any other response will be penalized. JSON structure example:

``````json
{{
    `"title`": `"Define the Purpose`",
    `"isRequired`": true or false,
    `"description": `"The purpose is the reason or goal for which something is done or created.`",
    `"examples`": [
        `"The purpose of this meeting is to discuss our quarterly goals.`",
        `"The purpose of the new marketing campaign is to increase brand awareness.`",
        `"The purpose of this charity event is to raise funds for a good cause.`"
    ],
    `"importance`": `"Defining the purpose is important because it helps to give direction and focus to any task or project. It allows individuals and organizations to set clear goals and make decisions that align with those goals.`",
    `"steps`": [
        `"1. Identify the desired outcome: The first step in defining the purpose is to identify what you want to achieve or accomplish.`",
        `"2. Consider the audience: Who is the purpose serving? It's important to consider the needs and interests of the audience when defining the purpose.`",
        `"3. Be specific: The purpose should be specific and clearly defined. This will help to avoid confusion and ensure everyone is on the same page.`",
        `"4. Use action-oriented language: Use strong and action-oriented language to define the purpose. This will help to motivate and inspire others to work towards the goal.`",
        `"5. Review and revise: It's important to regularly review and revise the purpose to ensure it is still relevant and aligned with the overall goals and objectives.`"
    ]
}}
``````

"@

foreach ($discussionStep in $discussionSteps) {
    $prompt2 = "$($discussionStep.description): $($discussionStep.details)"
    $prompt2 = $prompt2 -replace "`n", " " -replace "`r", " "
    #$prompt1 -f $prompt2
    $arguments = @($($prompt1 -f $prompt2), 800, "Creative", $mainEntity.name, $mainEntity.GPTModel, $true)
    #$arguments
    # Invoke an external function from another module
    #$output = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
    if ($output) {
        Write-Color -Text  $output -Color Blue -BackGroundColor DarkYellow
        Write-Color -Text "sleeping 5 sec." -Color White -BackGroundColor Green
        Start-Sleep -Seconds 5
        $outputAll += $output
    
    } 
    $output = ""
}
if ($outputAll) {
    Save-DiscussionResponse -TextContent $outputAll -Folder $script:TeamDiscussionDataFolder
}
#>






# Start discussion with configuration file
#StartDiscussion -configFilePath "team.json" -usermessage $usermessage

# Create instances of Entity for two entities
#$entityA = New-Object Entity -ArgumentList "EntityA", "RoleA", "DescriptionA", @(), "GPTModelA"
#$entityB = New-Object Entity -ArgumentList "EntityB", "RoleB", "DescriptionB", @(), "GPTModelB"

[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "1", "User")