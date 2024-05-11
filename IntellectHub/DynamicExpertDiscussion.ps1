[CmdletBinding()]
param(
    [string] $Topic = "The Impact of GPT on IT Microsoft Administrators",
    [int] $maxRounds = 5,
    [int] $expertCount = 2 
)

class Entity {
    [string] $name
    [string[]] $memory
    # A description of the entity
    [string] $Description
    # An array of skills that the entity possesses
    [string[]] $Skills
    
    
    Entity([string] $name, [string] $Description, [string[]] $Skills) {
        $this.name = $name
        $this.Description = $Description
        $this.Skills = $Skills
        $this.memory = @()

    }
    
    [string] generateStatement([string] $topic) {
        Write-Host ">Generate statement $($this.name)<"
        $prompt = @"
You are $($this.name) with skills $($this.skills -join ", "). What is your statement on topic: "$topic". Answer in a natural, human-like manner.
"@
        
        #$arguments = @($prompt, 1000, "UltraPrecise", $this.name, "udtgpt35turbo", $true)
        #Write-Host $prompt
        #$response = $this.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
        $response = $this.respond($prompt, ${function:InvokeGPT}, $prompt)
        return "$($this.name) on '$topic': $response"
    }
    
    #[string] respond([string[]] $statements, [scriptblock] $invokeGPTFunction, [string[]] $prompts, [Entity] $entity) {
    [string] respond([string[]] $statements, [scriptblock] $invokeGPTFunction, [string] $topic) {
        Write-Host ">Generate Respond for $($this.name)<"
        $otherStatements = $statements -join ", "
        $response = & $invokeGPTFunction $otherStatements $this  # Pass prompts and the current entity to the invokeGPT function
        $this.addToMemory($response)
        #return "$($this.name): $response`nOthers mentioned: $otherStatements"
        return "$($this.name): $response"
    }
    
    [void] addToMemory([string] $response) {
        $this.memory += $response
    }
    
    [string[]] recallMemory() {
        return $this.memory
    }

    # Method to invoke external function from another PowerShell module
    [string] InvokeCompletion(
        [string] $moduleName, 
        [string] $functionName, 
        [object[]] $arguments, 
        [switch]$Verbose
    ) {
        # Import the module if it's not already imported
        if (-not (Get-Module -Name $moduleName)) {
            Import-Module -Name $moduleName -ErrorAction Stop
        }
        # Invoke the function from the imported module
        return (& $functionName @arguments -Verbose:$Verbose)
    }
    
    # Method to invoke external function from another PowerShell module
    [string] InvokeChatCompletion([string] $PSmoduleName, [string] $functionName, [object[]] $arguments, [switch]$Verbose) {
        # Import the module if it's not already imported
        if (-not (Get-Module -Name $PSmoduleName)) {
            Import-Module -Name $PSmoduleName -ErrorAction Stop
        }
        # Invoke the function from the imported module
        return (& $functionName @arguments -Verbose:$Verbose)
    }
    
}

function ConductDiscussion {
    param (
        [Entity[]] $entities,
        [string] $topic,
        [int] $maxRounds
    )

    Write-Host "`nTopic: $topic" -BackgroundColor Cyan

    $roundNumber = 1
    while ($roundNumber -le $maxRounds) {
        Write-Host "`nRound $($roundNumber) of $($maxRounds):"
        foreach ($entity in $entities) {
            write-color ">ConductDiscussion start foreach $($entity.name)<"
            $otherStatements = @($entities | Where-Object { $_ -ne $entity } | ForEach-Object { 
                write-color ">ConductDiscussion $($_.name)<"
                $_.generateStatement($topic) 
             })
            Write-Host ">ConductDiscussion EntityRespond<"
            $EntityRespond = $entity.respond($otherStatements, ${function:InvokeGPT}, $topic)
            $prompts += $EntityRespond
            Write-Color -Text $EntityRespond -Color Green
        }
        $roundNumber++
    }
}

# Define the function to invoke GPT
function InvokeGPT {
    param (
        [string[]] $Statements,
        [entity] $entity
    )

    # Call your InvokeGPT function here
    #Write-color "InvokeGPT prompts for $($entity.name): '$prompts'" -BackGroundColor DarkYellow
    #Write-color "InvokeGPT pre-prompt for $($entity.name): '$prompt'" -BackGroundColor DarkYellow
    $Message = @"
Respond to the statements of others:
$($statements)
and give your arguments, ask questions.
"@
    $arguments = @($Message, 1000, "UltraPrecise", $entity.name, "udtgpt35turbo", $true)
    #Write-color "InvokeGPT prompt for $($entity.name): '$prompt'" -BackGroundColor DarkYellow
    $response = $entity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
    #Write-Color $response -BackGroundColor DarkGray
    return $response
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
    $script:TeamDiscussionDataFolder = Create-FolderInGivenPath -FolderPath $(Create-FolderInUserDocuments -FolderName "DynamicExpertDiscussion") -FolderName $currentDateTime
    if ($script:TeamDiscussionDataFolder) {
        PSWriteColor\Write-Color -Text "Team discussion folder was created '$script:TeamDiscussionDataFolder'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Warning -Message "Failed to create discussion folder"
    return $false
}
#endregion Creating Team Discussion Folder

#region Loading Experts and Creating Entities
Try {
    # Load the experts data from the JSON file
    $expertsData = Get-Content -Path "experts.json" -Raw | ConvertFrom-Json
    # Initialize an empty array to store the entities
    $entities = @()
    # Loop through each expert in the data
    foreach ($expert in $expertsData) {
        # Create a dynamic count of expert entities
        $entities += [Entity]::new($expert.'Expert Type', $expert.Description, $expert.Skills)
    }
    if ($entities) {
        PSWriteColor\Write-Color -Text "Entities were created ($($entities.count))" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Error -Message "Failed to create entities"
    return $false
}
#endregion

$mainEntity = $entities[0]

#region Expert Recommendation
PSWriteColor\Write-Color -Text "Experts recommendation " -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine
$output = Get-ExpertRecommendation -Entity $mainEntity -usermessage $topic -Experts $entities -expertcount $expertCount
$attempts = 0
$maxAttempts = 5
while ($attempts -lt $maxAttempts -and -not (Test-IsValidJson $output)) {
    PSWriteColor\Write-Color -Text "Data pre-processing " -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -NoNewLine -StartTab 1
    $output = CleantojsonLLM -dataString $output -entity $mainEntity
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
$expertstojob = $entities | Where-Object { $_.Name -in $expertstojob.jobexperts }
if ($expertstojob) {
    PSWriteColor\Write-Color -Text "Experts were choosed by $($mainEntity.Name) ($($expertstojob.Count)): $($expertstojob.Name -join ", ")" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    $script:ProjectGoalFileFulleNamepath = Save-DiscussionResponse -TextContent $output -Folder $script:TeamDiscussionDataFolder -type "ExpertsRecommendation" -ihguid $ihguid
    foreach ($experttojob in $expertstojob) {
        write-Verbose $($experttojob.Name)
    }
    PSWriteColor\Write-Color -Text "Experts recommendation finished" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime -StartTab 1
}
#endregion Expert Recommendation

# Conduct the discussion with a limit on the number of rounds
ConductDiscussion -entities $expertstojob -topic $topic -maxRounds $maxRounds
