# Load configuration from JSON file
function LoadConfigurationFromFile {
    param([string] $filePath)

    # Read configuration from file
    $configData = Get-Content -Path $filePath -Raw | ConvertFrom-Json

    # Parse entity data
    $entities = @()
    foreach ($entityData in $configData.Entities) {
        $entity = [Entity]::new($entityData.Name, $entityData.Role, $entityData.Description, $entityData.Skills, $entityData.GPTModel)
        $entities += $entity
    }

    return $entities
}

function Extract-PowershellCodeBlocks {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TextContent,
        [Parameter(Mandatory = $false)]
        [string]$Folder = "$([Environment]::GetFolderPath('MyDocuments'))\IH",
        [string]$ihguid
    )

    # Check if the folder exists, if not, create it
    if (!(Test-Path -Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder | Out-Null
    }

    # Define the regex pattern
    $pattern = '(?s)(?<=)```powershell\n([\s\S]*?)```\n'

    # Get all matches and iterate through them
    $matches = [regex]::Matches($TextContent, $pattern)
    foreach ($match in $matches) {

        # Get the captured text from the group
        $code = $match.Groups[1].Value

        if (![string]::IsNullOrEmpty($code)) {

            # Save the code to a file, using a unique name
            $fileName = "code" + $ihguid + ".ps1"
            $filePath = Join-Path -Path $Folder -ChildPath $fileName
            $code | Out-File -FilePath $filePath -Encoding UTF8
            # Print a message to indicate successful extraction
            Write-Host "Code block extracted and saved to $filePath"
        }

    }
}

function Create-FolderInUserDocuments {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderName
    )

    # Get the path to the user's Documents folder
    $UserDocumentsPath = [Environment]::GetFolderPath('MyDocuments')

    # Combine the Documents path with the folder name to get the full path
    $FolderPath = Join-Path -Path $UserDocumentsPath -ChildPath $FolderName

    # Check if the folder exists, if not, create it
    if (!(Test-Path -Path $FolderPath)) {
        New-Item -ItemType Directory -Path $FolderPath | Out-Null
    }

    # Return the full path of the folder
    return $FolderPath
}
function Create-FolderInGivenPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,
        [Parameter(Mandatory = $true)]
        [string]$FolderName
    )

    try {
        write-verbose "Create-FolderInGivenPath: $FolderPath"
        write-verbose "Create-FolderInGivenPath: $FolderName"

        # Combine the Folder path with the folder name to get the full path
        $FullFolderPath = Join-Path -Path $FolderPath -ChildPath $FolderName.trim()

        write-verbose "Create-FolderInGivenPath: $FullFolderPath"
        write-verbose $FullFolderPath.gettype()
        # Check if the folder exists, if not, create it
        if (-not $(Test-Path -Path $FullFolderPath)) {
            New-Item -ItemType Directory -Path $FullFolderPath | Out-Null
        }

        # Return the full path of the folder
        return $FullFolderPath
    }
    catch {
        Write-Error -Message "Failed to create folder at path: $FullFolderPath"
        return $null
    }
}
function Save-DiscussionResponse {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TextContent,
        [Parameter(Mandatory = $false)]
        [string]$Folder = "$([Environment]::GetFolderPath('MyDocuments'))\IH",
        $type = "discussionResponse",
        [string]$ihguid
    )

    # Check if the folder exists, if not, create it
    if (!(Test-Path -Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder | Out-Null
    }

    # Save the discussion response to a file, using a unique name
    $fileName = $type + $ihguid + ".txt"
    $filePath = Join-Path -Path $Folder -ChildPath $fileName
    $TextContent.trim() | Out-File -FilePath $filePath -Encoding UTF8

    # Print a message to indicate successful saving
    Write-Verbose "Data '$type' saved to '$fileName'"

    # Return the full path of the file
    return $filePath
}
function Get-DiscussionStepsFromJson {
    param(
        [string] $FilePath
    )

    # Read JSON data from file
    $jsonData = Get-Content -Path $FilePath -Raw | ConvertFrom-Json

    # Return the discussion steps
    return $jsonData.DiscussionSteps
}

function Get-ExpertsFromJson {
    param(
        [string] $FilePath = "experts.json"
    )

    # Check if the file exists
    if (!(Test-Path -Path $FilePath)) {
        Write-Error "File $FilePath does not exist."
        return $null
    }

    # Read JSON data from file
    $jsonData = Get-Content -Path $FilePath -Raw | ConvertFrom-Json

    # Return the experts
    return $jsonData
}

# Main function to start discussion
function StartDiscussion {
    param(
        [string] $configFilePath,
        $usermessage,
        [string]$ihguid
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
    ManageDiscussion -entityA $entities[0] -entityB $entities[1] -usermessage $prompt -ihguid $ihguid

    # Process and display response
    #Write-Output $response
}

# Function to manage discussion between two entities
function ManageDiscussion {
    param(
        [Entity] $entityA, 
        [Entity] $entityB, 
        $userMessage = "", 
        [string]$model),
        [string]$ihguid

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

        Extract-PowershellCodeBlocks -TextContent $responseFromA -Folder $script:TeamDiscussionDataFolder -ihguid $ihguid



        $Discussion += $EntityBsay


        PSWriteColor\Write-Color -Text "$($entityB.Name) thinking..." -Color Blue -BackGroundColor Cyan -LinesBefore 1 -Encoding utf8 -ShowTime

        PSWriteColor\Write-Color -Text "$($entityB.Name) systemprompt: $userMessage  usermessage: History of discussion:`n###`n $discussion `n###`n" -Color Blue -BackGroundColor Cyan -LinesBefore 1 -Encoding utf8 -ShowTime


        # Send prompt to Entity B
        $responseFromB = Invoke-PSAOAIchatCompletion -SystemPrompt $userMessage -usermessage "History of discussion:`n###`n $discussion `n###`n" -OneTimeUserPrompt -simpleresponse -Mode Precise -Deployment $entityB.GPTModel  -APIVersion "2024-03-01-preview"

        PSWriteColor\Write-Color -Text "$($entityB.Name) respond:" -Color Blue -BackGroundColor Cyan -LinesBefore 1 -Encoding utf8 -ShowTime


        $Discussion += $responseFromB

        # Process response from Entity B
        Write-Output $responseFromB

        Extract-PowershellCodeBlocks -TextContent $responseFromB -Folder $script:TeamDiscussionDataFolder -ihguid $ihguid

    }
    PSWriteColor\Write-Color -Text "Summary:" -Color DarkYellow  -BackGroundColor DarkGray -LinesBefore 1 -Encoding utf8 -ShowTime
    Invoke-PSAOAIchatCompletion -SystemPrompt "Summarize and show key elements" -usermessage "Discussion history: `n###`n$Discussion`n###`n" -OneTimeUserPrompt -simpleresponse -Mode Precise -Deployment "udtgpt4p" -APIVersion "2024-03-01-preview"
}

function Build-EntityObject {
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
    $EntityObject = New-Object Entity -ArgumentList $Name, $Role, $Description, $Skills, $GPTType, $GPTModel

    # Return the main entity
    return $EntityObject
}

# This function is used to clear the LLMDataJSON
function Clear-LLMDataJSON {
    <#
  .SYNOPSIS
  This function clears the LLMDataJSON.
  
  .DESCRIPTION
  The Clear-LLMDataJSON function takes a string of data as input, finds the first instance of '[' and the last instance of ']', and returns the substring between these two characters. This effectively removes any characters before the first '[' and after the last ']'.
  
  .PARAMETER data
  A string of data that needs to be cleared.
  
  .EXAMPLE
  $data = "{extra characters}[actual data]{extra characters}"
  Clear-LLMDataJSON -data $data
  #>
    param (
        # The data parameter is mandatory and should be a string
        [Parameter(Mandatory = $true)]
        [string]$data
    )
    # Find the first occurrence of '[' and remove everything before it
    $data = $data.Substring($data.IndexOf('{'))
    # Find the last occurrence of ']' and remove everything after it
    $data = $data.Substring(0, $data.LastIndexOf('}') + 1)
    # Return the cleaned data
    return $data
}
  

function Extract-JSON {
    param (
        [Parameter(Mandatory = $true)]
        [string]$inputString
    )

    Write-Verbose "Extract-JSON: inputstring:"
    Write-Verbose $($inputString | out-string)

    # Define a regular expression pattern to match JSON
    $jsonPattern = '(?s)\{.*?\}|\[.*?\]'

    # Find JSON substring using regex
    $jsonSubstrings = $inputString | Select-String -Pattern $jsonPattern -AllMatches | ForEach-Object { $_.Matches.Value }
    Write-Verbose "Extract-JSON: jsonSubstrings:"
    Write-Verbose $($jsonSubstrings | out-string)

    # Initialize an array to hold valid JSON objects
    $validJsonObjects = @()

    # Check if JSON substring was found
    if ($jsonSubstrings) {
        # Loop through each JSON substring
        foreach ($jsonSubstring in $jsonSubstrings) {
            # Parse JSON substring
            try {
                $jsonObject = Test-IsValidJson $jsonSubstring
                Write-Verbose "Extract-JSON: JSON extracted and parsed successfully."
                # Save parsed JSON into the array
                $validJsonObjects += $jsonObject
            }
            catch {
                Write-Verbose "Extract-JSON: Failed to parse JSON."
            }
        }
    }
    else {
        Write-Verbose "Extract-JSON: No JSON found in the string."
    }

    # Return the array of valid JSON objects
    return $validJsonObjects
}

<#
.SYNOPSIS
This function tests if a given string is a valid JSON.

.DESCRIPTION
The function takes a string as input, trims it, and then tries to convert it to a JSON object. If the conversion is successful, the function returns the original string. If the conversion fails, the function returns $false.

.PARAMETER jsonString
The string to be tested for JSON validity.

.EXAMPLE
Test-IsValidJson -jsonString '{"name":"John", "age":30, "city":"New York"}'
#>
function Test-IsValidJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$jsonString
    )
    $jsonString = $jsonString.trim()
    if ([string]::IsNullOrEmpty($jsonString)) {
        Write-Host "JSON is empty"
        return $false
    }
    Write-Verbose "Test-IsValidJson: jsonString: '$jsonString'"
    try {
        $null = $jsonString | ConvertFrom-Json -ErrorAction Stop
        return $jsonString
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
This function is a placeholder for the Get-ExpertRecommendation function.

.DESCRIPTION
The function is currently empty and needs to be implemented.
#>
function Get-ExpertRecommendation {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Entity,
        [Parameter(Mandatory = $true)]
        [string]$usermessage,
        $Experts
    )


    $ExperCountToChoose = " "
    $ExperCountToChoose = " two "

    $Message = @"
User need help. The task is '${usermessage}'. Analyze the user's task to choose${ExperCountToChoose}of the most useful experts to get the job done. Response must be as text json object with only Name of choosed experts. You must response as JSON:
{
    "JobExperts":  [
                      "",
                      ...,
                      ""
                   ]
}

List of available experts:
$($Experts | convertto-json)
"@

    $Message = @"
Your role is a JSON Expert. The task is to analyze problem '${usermessage}' and choose${ExperCountToChoose}of the most useful experts from available to get the job done. MUST respond with json structure where 'jobexperts' are Name of choosed experts.
$responsejson1

List of available experts:
$($Experts | convertto-json)
"@

    Write-Verbose $Message
    $arguments = @($Message, 800, "Precise", $Entity.name, $Entity.GPTModel, $true)
    try {
        $output = $Entity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
        return $output
    }
    catch {
        Write-Error -Message "Failed to get expert recommendation"
        return $false
    }
}

function CleantojsonLLM {
    param (
        [Parameter(Mandatory = $true)]
        [string]$dataString,
        [Parameter(Mandatory = $true)]
        [object]$entity
    )

    $responsejson1 = @'
{
    "jobexperts":  [
                    "{Name1}",
                    "{Name2}",
                    ...
                    "{NameN}"
                    ]
}
'@

    $Message = @"
###Instruction###

You must clean data and leave only JSON text object without block code. If there is no json data then create it with structure:

$responsejson1

###Data to clean###

$dataString
"@ | out-string

    Write-Color -Text "LLM cleaning" -Color Magenta -BackGroundColor DarkGreen
    $arguments = @($Message, 800, "Precise", $entity.name, $entity.GPTModel, $true)
    write-verbose ($arguments | Out-String)
    try {
        $output = $entity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
        Write-Verbose $output
        Write-Color -Text "Function cleaning" -Color Magenta -BackGroundColor DarkGreen
        $output = Clear-LLMDataJSOn $output
        return $output
    }
    catch {
        Write-Error -Message "Failed to clean and invoke completion"
        return $false
    }
}

function Get-FolderNameTopic {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Entity,
        [Parameter(Mandatory = $true)]
        [string]$usermessage
    )

    $responsejson1 = @"
{
    `"FolderName`":  `"`"
}
"@

    $Message = @"
Suggest short and creative folder name for the given task '${usermessage}'. Folder name must have only characters, and any white spaces will be penalized. Completion response must be as json text object. You must response as JSON syntax only, other elements, like text beside JSON will be penalized. JSON text object syntax to follow:
$responsejson1
"@

    $Message = @"
###Instructions###
Your task is to generate english JSON for a developer to use in code. The specific task is to create a JSON structure for the short and creative folder name with no whitespaces, based on description "${usermessage}". The response must be in JSON format ready to be copied and pasted into a code snippet. Every json value must be in english. Modify only the values, in the given JSON example structure: 
{ "FolderName": "" }
"@
    Write-Verbose $Message
    $arguments = @($Message, 100, "UltraPrecise", $Entity.name, $Entity.GPTModel, $true)
    try {
        $output = $Entity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
        return $output
    }
    catch {
        Write-Error -Message "Failed to get name recommendation"
        return $false
    }
}

function Get-LLMResponse {
    param(
        [Parameter(Mandatory = $true)]
        [string]$usermessage,
        $Entity,
        $expert,
        $goal,
        $title,
        $description,
        $importance,
        $steps,
        $examples
    )

    #Write-Verbose "Defining ${title} for '$usermessage'"

    $responsejson1 = @"
{
    `"$title`":  `"`"
}
"@
    
    $Message = @"
You are expert '$($expert.Description)' with skills $($expert.skills -join ", "). You are a part of team of experts. Your task is make your view for $title - $description To user's project described as '$usermessage' and definied by Project Manager as a goal: 
$($goal.trim())
You must suggest project goal for the given task '${usermessage}'. 
Completion response your view for $title MUST be as json text object. You must response as JSON syntax only, other elements, like text beside JSON will be penalized. JSON text object syntax to follow:
$responsejson1
"@
    Write-Verbose $Message
    $arguments = @($Message, 500, "Focused", $Entity.name, $Entity.GPTModel, $true)
    try {
        $output = $Entity.InvokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
        return $output
    }
    catch {
        Write-Error -Message "Failed to defining $title"
        return $false
    }
}

function Shorten-Text {
    param (
        [Parameter(Mandatory = $true)]
        [string]$text,
        [Parameter(Mandatory = $false)]
        [int]$wordscount = 100
    )

    # Split the text into words
    $words = $text -split " "
    write-Verbose "Shorten-Text: $($words.count) words"

    # Check if the text has more words than the specified word count
    if ($words.Count -gt $wordscount) {
        # Show the first half and last half words based on the word count
        $firstHalf = [math]::Floor($wordscount / 2)
        $lastHalf = [math]::Ceiling($wordscount / 2)
        $shortenedText = $words[0..($firstHalf - 1)] + "`n...`n" + $words[ - $lastHalf..-1]
        write-Verbose "Text was shortened due to its length:"
        return $shortenedText -join " "
    }
    else {
        # If the text has fewer or equal words to the specified word count, return it as is
        return $text
    }
}
