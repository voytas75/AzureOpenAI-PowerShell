param(
    $usermessage
)


# Main function to start discussion
function StartDiscussion {
    param(
        [string] $configFilePath,
        $usermessage
    )

    # Load configuration from file
    $entities = LoadConfigurationFromFile -filePath $configFilePath
    $entities
    # Start CLI interface for discussion
    # Implement CLI commands for starting discussion, adding entities, etc.

    # Example: Send data to GPT and receive response
    $prompt = @'
    How to in powershell using regex get all powershell code between "<empty line>```powershell","```<empty line>" and save it to separate file. there may be more then one blocks of code. Example of text to test regex:
    ###example###
    I would like to add a suggestion to enhance the function's flexibility. It might be beneficial to include a parameter for specifying the log file path, so users can direct the output to a location of their choice without modifying the function's code. Here's an updated version of the function with this improvement:

    ```powershell
    function Write-Log {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            [string]$Level = "Info",
            [string]$LogPath = "C:\Logs\log.txt"
        )
    
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $log = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message
    
        Write-Output $log | Out-File -FilePath $LogPath -Append
    }
    ```
    
    Now, users can specify a different log path when calling the function, like so:
    
    ```powershell
    Write-Log -Message "This is a log message" -LogPath "D:\CustomLogs\mylog.txt"
    ```
    
    This will write the log message to "D:\CustomLogs\mylog.txt" instead of the default location.
    ###end of example###
'@
    $prompt = @"
User want to create powershell application to collaboration, knowledge sharing, problem-solving between experts as standalone gpt models. it be used by IT professionals, developers. This can include only text interface chat. no security measures for now. i need ideas for further development. user see this app in this way 'user can define team by json file, the team start discussion to reach user goal, i.e. write powershell function, or develop ideas for option for existing application. the team is group of independent gpt models what is better then one gpt with advanced prompt. so in general i want to build multi gpt team to help with work'. now we only try to make functions and ideas for options of application and eaven technical way of doing something like how to main engine should look like, where store the configuration data.

Here's ideas list:

- **Team Management**: Create and manage teams via a JSON file, with each team having its own members and projects.
- **Real-Time Collaboration**: Implement text-based chat for instant communication.
- **AI-Powered Suggestions**: Use GPT models to provide suggestions based on discussions and industry practices.
- **Customizable Prompts**: Allow customization of discussion prompts to focus on specific goals.
- **Code Generation**: Generate code snippets based on team discussions to aid development.
- **file-Based Storage**: Use files storage for accessibility and collaboration.
- **Role-Based Access Control**: Define roles and permissions to secure sensitive information.
- **User-Friendly Interface**: Design an intuitive interface for ease of use.
- **Gamification and Rewards**: Motivate team members with points or rewards.
- **Search and Knowledge Base**: Implement search functionality and create a knowledge base for shared solutions.
- **Automation and Analytics**: Automate tasks, handle errors intelligently, and analyze user activity.
- **Collaborative Editing and Documenting**: Allow real-time code editing and collaborative document creation.
"@
    $prompt = $usermessage
    PSWriteColor\Write-Color -Text $prompt -Color Blue -BackGroundColor Cyan
    #$response = Invoke-PSAOAICompletion -usermessage $prompt -MaxTokens 500 -mode Creative -simpleresponse

    # Start discussion between the two entities
    ManageDiscussion -entityA $entities[0] -entityB $entities[1] -usermessage $prompt

    # Process and display response
    #Write-Output $response
}

# Function to manage discussion between two entities
function ManageDiscussion {
    param(
        [Entity] $entityA, 
        [Entity] $entityB, 
        $userMessage = "", 
        [string]$model)

    $Discussion = ""

    $entityAsaid = "{0} said:" -f $entityA.Name
    $EntityAsay = "i am {0}. My role is {1}. " -f $entityA.Name, $entityA.Role

    $entityBsaid = "{0} said:" -f $entityB.Name
    $EntityBsay = "I am {0}. My role is {1}. " -f $entityB.Name, $entityB.Role

    # Start discussion loop
    for ($i = 0; $i -lt 5; $i++) {
        # Example: Discussion loop runs 5 times
        $Discussion += $EntityAsay


        $promptEntityA += $userMessage
        $promptEntityA += "History of discussion:`n###`n $discussion `n###`n" 


        PSWriteColor\Write-Color -Text "$($entityA.Name) thinking..." -Color Blue -BackGroundColor Cyan -LinesBefore 1 -Encoding utf8 -ShowTime

        PSWriteColor\Write-Color -Text "$($entityA.Name) usermessage: $promptEntityA" -Color Blue -BackGroundColor Cyan -LinesBefore 1 -Encoding utf8 -ShowTime


        # Send prompt to Entity A
        $responseFromA = Invoke-PSAOAICompletion -usermessage $promptEntityA -MaxTokens 800 -mode Creative -simpleresponse -Deployment $entityA.GPTModel -APIVersion "2024-03-01-preview"

        PSWriteColor\Write-Color -Text "$($entityA.Name) respond:" -Color Blue -BackGroundColor Cyan -LinesBefore 1 -Encoding utf8 -ShowTime


        $Discussion += $responseFromA

        # Process response from Entity A
        Write-Output $responseFromA

        Extract-PowershellCodeBlocks -TextContent $responseFromA -Folder $script:TeamDiscussionDataFolder



        $Discussion += $EntityBsay


        PSWriteColor\Write-Color -Text "$($entityB.Name) thinking..." -Color Blue -BackGroundColor Cyan -LinesBefore 1 -Encoding utf8 -ShowTime

        PSWriteColor\Write-Color -Text "$($entityB.Name) systemprompt: $userMessage  usermessage: History of discussion:`n###`n $discussion `n###`n" -Color Blue -BackGroundColor Cyan -LinesBefore 1 -Encoding utf8 -ShowTime


        # Send prompt to Entity B
        $responseFromB = Invoke-PSAOAIchatCompletion -SystemPrompt $userMessage -usermessage "History of discussion:`n###`n $discussion `n###`n" -OneTimeUserPrompt -simpleresponse -Mode Precise -Deployment $entityB.GPTModel  -APIVersion "2024-03-01-preview"

        PSWriteColor\Write-Color -Text "$($entityB.Name) respond:" -Color Blue -BackGroundColor Cyan -LinesBefore 1 -Encoding utf8 -ShowTime


        $Discussion += $responseFromB

        # Process response from Entity B
        Write-Output $responseFromB

        Extract-PowershellCodeBlocks -TextContent $responseFromB -Folder $script:TeamDiscussionDataFolder

    }
    PSWriteColor\Write-Color -Text "Summary:" -Color DarkYellow  -BackGroundColor DarkGray -LinesBefore 1 -Encoding utf8 -ShowTime
    Invoke-PSAOAIchatCompletion -SystemPrompt "Summarize and show key elements" -usermessage "Discussion history: `n###`n$Discussion`n###`n" -OneTimeUserPrompt -simpleresponse -Mode Precise -Deployment "udtgpt4p" -APIVersion "2024-03-01-preview"
}

function Build-MainEntity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Role,
        [Parameter(Mandatory = $true)]
        [string]$Description,
        [Parameter(Mandatory = $true)]
        [string[]]$Skills,
        [Parameter(Mandatory = $true)]
        [string]$GPTType,
        [Parameter(Mandatory = $true)]
        [string]$GPTModel
    )

    # Create a new instance of the Entity class
    $mainEntity = New-Object Entity -ArgumentList $Name, $Role, $Description, $Skills, $GPTType, $GPTModel

    # Return the main entity
    return $mainEntity
}


# Define PowerShell class for Entity

# Import PSaoAI module
#Import-Module -Name PSaoAI
Import-module "D:\dane\voytas\Dokumenty\visual_studio_code\github\AzureOpenAI-PowerShell\PSAOAI\PSAOAI.psd1" -Force


$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$entityClassPath = Join-Path -Path $scriptPath -ChildPath "entity_class.ps1"
$helperFunctionsPath = Join-Path -Path $scriptPath -ChildPath "helper_functions.ps1"
. $helperFunctionsPath
. $entityClassPath


$mainEntity = Build-MainEntity -Name "MainEntity" -Role "MainRole" -Description "MainDescription" -Skills @("Skill1", "Skill2", "Skill3") -GPTType "azure" -GPTModel "udtgpt35turbo"

#$mainEntity
#Invoke-PSAOAICompletion [[-usermessage] <string>] [[-MaxTokens] <int>] [[-Mode] <string>] [[-User] <string>] [[-Deployment] <string>] [-simpleresponse]


#$arguments = @($userMessage, 800, "Creative", $mainEntity.name, $mainEntity.GPTModel, $true)
# Invoke an external function from another module
#$output = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments)


#, @("-usermessage", "i am $($mainEntity.Name)", "-MaxTokens", 800, "-mode", "Creative", "-simpleresponse", "-Deployment", $mainEntity.GPTModel, "-APIVersion", "2024-03-01-preview"))
# Use the output as needed
#Write-Color -Text  $output -Color Blue -BackGroundColor DarkYellow



#$functionName = "Invoke-PSAOAICompletion"
#$response = & $functionName @arguments | Out-String
#Write-Color -Text $response.trim() -Color Blue -BackGroundColor DarkYellow


$experts = Get-ExpertsFromJson -FilePath "experts.json"
#$experts




$discussionSteps = ReadDiscussionStepsFromJson -FilePath "discussion_steps.json"
$discussionSteps | measure | select -ExpandProperty count
$discussionSteps | measure | select count | fl 
$a = $discussionSteps | measure | select count
$a.count
$discussionSteps.where{ $_.step -eq 1 }

$prompt1 = @"
expand topic '{0}' and answer show as a JSON.
JSON structure:

``````json
{
    `"title`": `"Define the Purpose`",
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
}
``````

"@

foreach ($discussionStep in $discussionSteps) {
    $prompt2 = "- $($discussionStep.description) $($discussionStep.details)" | Out-String
    $prompt1 
    #-f $prompt2
    #$arguments = @($($prompt1 -f $prompt2), 800, "Creative", $mainEntity.name, $mainEntity.GPTModel, $true)
    # Invoke an external function from another module
    #$output = $mainEntity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments)
    #Write-Color -Text  $output -Color Blue -BackGroundColor DarkYellow
}


# Get the current date and time
$currentDateTime = Get-Date -Format "yyyyMMdd_HHmmss"


# Create a folder with the current date and time as the name in the example path
$script:TeamDiscussionDataFolder = Create-FolderInGivenPath -FolderPath $(Create-FolderInUserDocuments -FolderName "IH") -FolderName $currentDateTime


# Start discussion with configuration file
#StartDiscussion -configFilePath "team.json" -usermessage $usermessage

# Create instances of Entity for two entities
#$entityA = New-Object Entity -ArgumentList "EntityA", "RoleA", "DescriptionA", @(), "GPTModelA"
#$entityB = New-Object Entity -ArgumentList "EntityB", "RoleB", "DescriptionB", @(), "GPTModelB"

