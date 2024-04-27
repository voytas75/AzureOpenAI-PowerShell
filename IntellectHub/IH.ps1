[CmdletBinding()]
param(
    $usermessage
)

# Define PowerShell class for Entity

# Import PSaoAI module
[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "0", "User")
Import-Module -Name PSaoAI
#Import-module "D:\dane\voytas\Dokumenty\visual_studio_code\github\AzureOpenAI-PowerShell\PSAOAI\PSAOAI.psd1" -Force 

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
    
        $output

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
    $script:ProjectGoalFileFulleNamepath = Save-DiscussionResponse -TextContent $output -Folder $script:ProjectFolderFullNamePath -type "ExpertsRecommendation"
    foreach ($experttojob in $expertstojob) {
        write-Verbose $($experttojob.Name)
    }
}
#endregion

#region Define Project Goal
$projectGoal = Define-ProjectGoal -usermessage $usermessage -Entity $mainEntity
if ($projectGoal) {
    
    $script:ProjectGoalFileFulleNamepath = Save-DiscussionResponse -TextContent $projectGoal -Folder $script:ProjectFolderFullNamePath -type "ProjectGoal"
    if (Test-Path $script:ProjectGoalFileFulleNamepath) {
        PSWriteColor\Write-Color -Text "Project goal was definied '$script:ProjectGoalFileFulleNamepath'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
    
}

Write-Verbose "Project goal: $projectGoal"
#endregion


foreach ($discussionStep in $discussionSteps) {
    if ($discussionStep.isRequired) {
        $discussionStep.title
        $discussionStep.description
        $discussionStep.steps -join "`n"
        foreach ($expertToJob in $expertstojob) {
            Get-LLMResponse -usermessage $usermessage -entity $mainEntity -expert $expertToJob -goal $projectGoal -title $discussionStep.title -description $discussionStep.description -importance $discussionStep.importance -steps ($discussionStep.steps -join "`n") -examples $discussionStep.examples
        }
    }  
}




[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "1", "User")