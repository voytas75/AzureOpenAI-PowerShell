<#PSScriptInfo
.VERSION 1.5.0
.GUID f0f4316d-f106-43b5-936d-0dd93a49be6b
.AUTHOR voytas75
.TAGS ai,psaoai,llm,project,team,gpt
.PROJECTURI https://github.com/voytas75/AzureOpenAI-PowerShell/tree/master/AIPSTeam/README.md
.EXTERNALMODULEDEPENDENCIES PSAOAI, PSScriptAnalyzer
.RELEASENOTES
1.5.0: minor fixes, modularize PSScriptAnalyzer logic, load, save project status.
1.4.0: modularize feedback.
1.3.0: add to menu Generate documentation, The code research, Requirement for PSAOAI version >= 0.2.1 , fix CyclomaticComplexity.
1.2.1: fix EXTERNALMODULEDEPENDENCIES
1.2.0: add user interaction and use PSScriptAnalyzer.
1.1.0: default value for DeploymentChat.
1.0.7: Added 'DeploymentChat' parameter.
1.0.6: Updated function calls to Add-ToGlobalResponses.
1.0.5: code export fix.
1.0.4: code export fix.
1.0.3: requirements.
1.0.2: publishing, check version fix, dependience.
1.0.1: initializing.
#>

#Requires -Modules PSAOAI
#Requires -Modules PSScriptAnalyzer

<# 
.SYNOPSIS 
This script emulates a team of specialists working together on a PowerShell project.

.DESCRIPTION 
The script simulates a team of specialists, each with a unique role in executing a project. The user input is processed by one specialist who performs their task and passes the result to the next specialist. This process continues until all tasks are completed.

.PARAMETER userInput 
This parameter defines the project outline as a string. The default value is a project to monitor RAM load and display a color block based on the load levels. This parameter can also accept input from the pipeline.

.PARAMETER Stream 
This parameter controls whether the output should be streamed live. By default, this parameter is set to $true, enabling live streaming. If set to $false, live streaming is disabled.

.PARAMETER NOPM 
This optional switch disables the Project Manager functions when used.

.PARAMETER NODocumentator 
This optional switch disables the Documentator functions when used.

.PARAMETER NOLog
This optional switch disables the logging functions when used.

.PARAMETER LogFolder
This parameter specifies the folder where logs should be stored.

.INPUTS 
System.String. You can pipe a string to the 'userInput' parameter.

.OUTPUTS 
The output varies depending on how each specialist processes their part of the project. Typically, text-based results are expected, which may include status messages or visual representations like graphs or color blocks related to system metrics such as RAM load, depending on the user input specification provided via the 'userInput' parameter.

.EXAMPLE 
PS> "A PowerShell project to monitor CPU usage and display dynamic graph." | .\AIPSTeam.ps1 -Stream $false

This command runs the script without streaming output live (-Stream $false) and specifies custom user input about monitoring CPU usage instead of RAM, displaying it through dynamic graphing methods rather than static color blocks.

.NOTES 
Version: 1.5.0
Author: voytas75
Creation Date: 05.2024
Purpose/Change: Initial release for emulating teamwork within PowerShell scripting context, rest in PSScriptInfo Releasenotes, .

.LINK
https://www.powershellgallery.com/packages/AIPSTeam
https://github.com/voytas75/AzureOpenAI-PowerShell/tree/master/AIPSTeam/README.md
#>
param(
    [Parameter(ValueFromPipeline = $true)]
    [string] $userInput = "Monitor RAM usage and show a single color block based on the load.",
    [bool] $Stream = $true,
    [switch] $NOPM,
    [switch] $NODocumentator,
    [switch] $NOLog,
    [string] $LogFolder,
    [string] $DeploymentChat = [System.Environment]::GetEnvironmentVariable("PSAOAI_API_AZURE_OPENAI_CC_DEPLOYMENT", "User"),
    [Parameter(ParameterSetName = 'LoadStatus')]
    [string] $LoadProjectStatus
)

$AIPSTeamVersion = "1.5.0"

#region ProjectTeamClass
<#
.SYNOPSIS
The ProjectTeam class represents a team member with a specific expertise.

.DESCRIPTION
Each team member has a name, role, prompt, and a function to process the input. They can also log their actions, store their responses, and pass the input to the next team member.

.METHODS
DisplayInfo: Displays the team member's information.
DisplayHeader: Displays the team member's name and role.
ProcessInput: Processes the input and returns the response.
SetNextExpert: Sets the next team member in the workflow.
GetNextExpert: Returns the next team member in the workflow.
AddLogEntry: Adds an entry to the log.
Notify: Sends a notification (currently just displays a message).
GetMemory: Returns the team member's memory (responses).
GetLastMemory: Returns the last response from the team member's memory.
SummarizeMemory: Summarizes the team member's memory.
ProcessBySpecificExpert: Processes the input by a specific team member.
#>
# Define the ProjectTeam class
class ProjectTeam {
    # Define class properties
    [string] $Name  # Name of the team member
    [string] $Role  # Role of the team member
    [string] $Prompt  # Prompt for the team member
    [ProjectTeam] $NextExpert  # Next expert in the workflow
    [System.Collections.ArrayList] $ResponseMemory  # Memory to store responses
    [double] $Temperature  # Temperature parameter for the response function
    [double] $TopP  # TopP parameter for the response function
    [string] $Status  # Status of the team member
    [System.Collections.ArrayList] $Log  # Log of the team member's actions
    [scriptblock] $ResponseFunction  # Function to process the input and generate a response
    [string] $LogFilePath  # Path to the log file
    [array] $FeedbackTeam  # Team of experts providing feedback
    
    # Constructor for the ProjectTeam class
    ProjectTeam([string] $name, [string] $role, [string] $prompt, [double] $temperature, [double] $top_p, [scriptblock] $responseFunction) {
        $this.Name = $name
        $this.Role = $role
        $this.Prompt = $prompt
        $this.NextExpert = $null
        $this.ResponseMemory = @()
        $this.Temperature = $temperature
        $this.TopP = $top_p
        $this.Status = "Not Started"
        $this.Log = @()
        $this.ResponseFunction = $responseFunction
        $this.LogFilePath = "$script:TeamDiscussionDataFolder\$name.log"
        $this.FeedbackTeam = @()
    }

    # Method to display the team member's information
    [PSCustomObject] DisplayInfo([int] $display = 1) {
        # Create an ordered dictionary to store the information
        $info = [ordered]@{
            "Name"              = $this.Name
            "Role"              = $this.Role
            "System prompt"     = $this.Prompt
            "Temperature"       = $this.Temperature
            "TopP"              = $this.TopP
            "Responses"         = $this.ResponseMemory | ForEach-Object { "[$($_.Timestamp)] $($_.Response)" }
            "Log"               = $this.Log -join ', '
            "Log File Path"     = $this.LogFilePath
            "Feedback Team"     = $this.FeedbackTeam
            "Next Expert"       = $this.NextExpert
            "Status"            = $this.Status
            "Response Function" = $this.ResponseFunction
        }
        
        # Create a custom object from the dictionary
        $infoObject = New-Object -TypeName PSCustomObject -Property $info

        # If display is set to 1, print the information to the console
        if ($display -eq 1) {
            Show-Header -HeaderText "Info: $($this.Name) ($($this.Role))"
            Write-Host "Name: $($infoObject.Name)"
            Write-Host "Role: $($infoObject.Role)"
            Write-Host "System prompt: $($infoObject.'System prompt')"
            Write-Host "Temperature: $($infoObject.Temperature)"
            Write-Host "TopP: $($infoObject.TopP)"
            Write-Host "Responses: $($infoObject.Responses)"
            Write-Host "Log: $($infoObject.Log)"
            Write-Host "Log File Path: $($infoObject.'Log File Path')"
            Write-Host "Feedback Team: $($infoObject.'Feedback Team')"
            Write-Host "Next Expert: $($infoObject.'Next Expert')"
            Write-Host "Status: $($infoObject.Status)"
            Write-Host "Response Function: $($infoObject.'Response Function')"
        }

        # Return the custom object
        return $infoObject
    }
    
    # Method to process the input and generate a response
    [string] ProcessInput([string] $userinput) {
        Show-Header -HeaderText "Current Expert: $($this.Name) ($($this.Role))"
        # Log the input
        $this.AddLogEntry("Processing input:`n$userinput")
        # Update status
        $this.Status = "In Progress"
        #write-Host $script:Stream
        try {
            # Use the user-provided function to get the response
            $response = & $this.ResponseFunction -SystemPrompt $this.Prompt -UserPrompt $userinput -Temperature $this.Temperature -TopP $this.TopP
            if (-not $script:Stream) {
                #write-host ($response | convertto-json -Depth 100)
                Write-Host $response
            }
            # Log the response
            $this.AddLogEntry("Generated response:`n$response")
            # Store the response in memory with timestamp
            $this.ResponseMemory.Add([PSCustomObject]@{
                    Response  = $response
                    Timestamp = Get-Date
                })
            $feedbackSummary = ""
            if ($this.FeedbackTeam.count -gt 0) {
                # Request feedback for the response
                $feedbackSummary = $this.RequestFeedback($response)
                # Log the feedback summary
                $this.AddLogEntry("Feedback summary:`n$feedbackSummary")
            }
            # Integrate feedback into response
            $responseWithFeedback = "$response`n`n$feedbackSummary"

            # Update status
            $this.Status = "Completed"
        }
        catch {
            # Log the error
            $this.AddLogEntry("Error:`n$_")
            # Update status
            $this.Status = "Error"
            throw $_
        }

        # Pass to the next expert if available
        if ($null -ne $this.NextExpert) {
            return $this.NextExpert.ProcessInput($responseWithFeedback)
        }
        else {
            return $responseWithFeedback
        }
    }

    [string] Feedback([ProjectTeam] $AssessedExpert, [string] $Expertinput) {
        Show-Header -HeaderText "Feedback by $($this.Name) ($($this.Role)) for $($AssessedExpert.name)"
        
        # Log the input
        $this.AddLogEntry("Processing input:`n$Expertinput")
        
        # Update status
        $this.Status = "In Progress"
        
        try {
            # Ensure ResponseMemory is initialized
            if ($null -eq $this.ResponseMemory) {
                $this.ResponseMemory = @()
                $this.AddLogEntry("Initialized ResponseMemory")
            }
            
            # Use the user-provided function to get the response
            $response = & $this.ResponseFunction -SystemPrompt $this.Prompt -UserPrompt $Expertinput -Temperature $this.Temperature -TopP $this.TopP
            
            # Log the response
            $this.AddLogEntry("Generated feedback response:`n$response")
            
            # Verify the response before adding to memory
            $this.AddLogEntry("Response before adding to memory: $response")
            
            # Store the response in memory with timestamp
            $responseObject = [PSCustomObject]@{
                Response  = $response
                Timestamp = Get-Date
            }
            $this.ResponseMemory.Add($responseObject)
            
            # Log after storing
            $this.AddLogEntry("Stored response at $(Get-Date): $response")
            
            # Update status
            $this.Status = "Completed"
        }
        catch {
            # Log the error
            $this.AddLogEntry("Error:`n$_")
            # Update status
            $this.Status = "Error"
            throw $_
        }
    
        return $response
    }
    

    [void] SetNextExpert([ProjectTeam] $nextExpert) {
        $this.NextExpert = $nextExpert
    }

    [ProjectTeam] GetNextExpert() {
        return $this.NextExpert
    }
    
    [void] AddLogEntry([string] $entry) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp]:`n$(Show-Header -HeaderText $entry -output)"
        $this.Log.Add($logEntry)
        if (-not [string]::IsNullOrEmpty($this.LogFilePath)) {
            # Write the log entry to the file
            Add-Content -Path $this.LogFilePath -Value $logEntry
        }
    }

    [void] Notify([string] $message) {
        # Placeholder for a method to send notifications
        Write-Host "Notification: $message"
    }

    [System.Collections.ArrayList] GetMemory() {
        return $this.ResponseMemory
    }

    [PSCustomObject] GetLastMemory() {
        if ($this.ResponseMemory.Count -gt 0) {
            return $this.ResponseMemory[-1]
        }
        else {
            return $null
        }
    }

    [string] SummarizeMemory() {
        $summaryPrompt = "Summarize the following memory entries:"
        $memoryEntries = $this.ResponseMemory | ForEach-Object { "[$($_.Timestamp)] $($_.Response)" }
        $fullPrompt = "$summaryPrompt`n`n$($memoryEntries -join "`n")"

        try {
            # Use the user-provided function to get the summary
            $summary = & $this.ResponseFunction -SystemPrompt $fullPrompt -UserPrompt "" -Temperature 0.7 -TopP 0.9
            # Log the summary
            $this.AddLogEntry("Generated summary:`n$summary")
            return $summary
        }
        catch {
            # Log the error
            $this.AddLogEntry("Error:`n$_")
            throw $_
        }
    }

    [string] ProcessBySpecificExpert([ProjectTeam] $expert, [string] $userinput) {
        return $expert.ProcessInput($userinput)
    }

    [System.Collections.ArrayList] RequestFeedback([string] $response) {
        $feedbacks = @()

        foreach ($FeedbackMember in $this.FeedbackTeam) {
            Show-Header -HeaderText "Feedback from $($FeedbackMember.Role) to $($this.Role)"
   
            # Send feedback request and collect feedback
            $feedback = SendFeedbackRequest -TeamMember $FeedbackMember.Role -Response $response -Prompt $FeedbackMember.Prompt -Temperature $this.Temperature -TopP $this.TopP -ResponseFunction $this.ResponseFunction
        
            if ($null -ne $feedback) {
                $FeedbackMember.ResponseMemory.Add([PSCustomObject]@{
                        Response  = $feedback
                        Timestamp = Get-Date
                    })

                $feedbacks += $feedback
            }
        }

        if ($feedbacks.Count -eq 0) {
            throw "No feedback received from team members."
        }

        return $feedbacks
    }

    [void] AddFeedbackTeamMember([ProjectTeam] $member) {
        $this.FeedbackTeam += $member
    }

    [void] RemoveFeedbackTeamMember([ProjectTeam] $member) {
        $this.FeedbackTeam = $this.FeedbackTeam | Where-Object { $_ -ne $member }
    }
}
#endregion ProjectTeamClass

#region Functions
function SendFeedbackRequest {
    param (
        [string] $TeamMember, # The team member to send the feedback request to
        [string] $Response, # The response to be reviewed
        [string] $Prompt, # The prompt for the feedback request
        [double] $Temperature, # The temperature parameter for the LLM model
        [double] $TopP, # The TopP parameter for the LLM model
        [scriptblock] $ResponseFunction # The function to generate the response
    )

    # Define the feedback request prompt
    $Systemprompt = $prompt 
    $NewResponse = @"
Review the following response and provide your suggestions for improvement as feedback to $($this.name). Generate a list of verification questions that could help to self-analyze. 
I will tip you `$100 when your suggestions are consistent with the project description and objectives. 

$($script:userInput.trim())

````````text
$($Response.trim())
````````

Think step by step. Make sure your answer is unbiased.
"@

    # Send the feedback request to the LLM model
    $feedback = & $ResponseFunction -SystemPrompt $SystemPrompt -UserPrompt $NewResponse -Temperature $Temperature -TopP $TopP

    # Return the feedback
    return $feedback
}

function Get-LastMemoryFromFeedbackTeamMembers {
    param (
        [array] $FeedbackTeam
    )

    $lastMemories = @()

    foreach ($FeedbackTeamMember in $FeedbackTeam) {
        $lastMemory = $FeedbackTeamMember.GetLastMemory().Response
        $lastMemories += $lastMemory
    }

    return ($lastMemories -join "`n")
}

function Add-ToGlobalResponses {
    param($response)
    $script:GlobalResponse += $response
}

function New-FolderAtPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [string]$FolderName
    )

    try {
        Write-Verbose "New-FolderAtPath: $Path"
        Write-Verbose "New-FolderAtPath: $FolderName"

        # Combine the Folder path with the folder name to get the full path
        $CompleteFolderPath = Join-Path -Path $Path -ChildPath $FolderName.trim()

        Write-Verbose "New-FolderAtPath: $CompleteFolderPath"
        Write-Verbose $CompleteFolderPath.gettype()
        # Check if the folder exists, if not, create it
        if (-not (Test-Path -Path $CompleteFolderPath)) {
            New-Item -ItemType Directory -Path $CompleteFolderPath -Force | Out-Null
        }

        # Return the full path of the folder
        return $CompleteFolderPath
    }
    catch {
        Write-Warning -Message "Failed to create folder at path: $CompleteFolderPath"
        return $null
    }
}

function Get-LatestVersion {
    param (
        [string]$scriptName
    )
  
    try {
        # Find the script on PowerShell Gallery
        $scriptInfo = Find-Script -Name $scriptName -ErrorAction Stop
  
        # Return the latest version
        return $scriptInfo.Version
    }
    catch {
        #Write-warning "Failed to get the latest version of $scriptName from PowerShell Gallery. $($_.exception)"
        return $null
    }
}

function Get-CheckForScriptUpdate {
    param (
        $currentScriptVersion,
        [string]$scriptName
    )
  
    # Retrieve the latest version of the script
    $latestScriptVersion = Get-LatestVersion -scriptName $scriptName
  
    if ($latestScriptVersion) {
        # Compare the current version with the latest version
        if (([version]$currentScriptVersion) -lt [version]$latestScriptVersion) {
            Write-Host " A new version ($latestScriptVersion) of $scriptName is available. You are currently using version $currentScriptVersion. " -BackgroundColor DarkYellow -ForegroundColor Blue
            write-Host "`n`n"
        } 
    }
    else {
        Write-Warning "Failed to check for the latest version of the script."
    }
}

function Show-Banner {
    Write-Host @'
 

     /$$$$$$  /$$$$$$ /$$$$$$$   /$$$$$$  /$$$$$$$$                               
    /$$__  $$|_  $$_/| $$__  $$ /$$__  $$|__  $$__/                               
   | $$  \ $$  | $$  | $$  \ $$| $$  \__/   | $$  /$$$$$$   /$$$$$$  /$$$$$$/$$$$ 
   | $$$$$$$$  | $$  | $$$$$$$/|  $$$$$$    | $$ /$$__  $$ |____  $$| $$_  $$_  $$
   | $$__  $$  | $$  | $$____/  \____  $$   | $$| $$$$$$$$  /$$$$$$$| $$ \ $$ \ $$
   | $$  | $$  | $$  | $$       /$$  \ $$   | $$| $$_____/ /$$__  $$| $$ | $$ | $$
   | $$  | $$ /$$$$$$| $$      |  $$$$$$/   | $$|  $$$$$$$|  $$$$$$$| $$ | $$ | $$
   |__/  |__/|______/|__/       \______/    |__/ \_______/ \_______/|__/ |__/ |__/ 
                                                                                  
   AI PowerShell Team                                     powered by PSAOAI Module
         
       https://github.com/voytas75/AzureOpenAI-PowerShell/tree/master/AIPSTeam
  
'@
    Write-Host @"
         The script is designed to simulate a project team working on a PowerShell project. The script creates different   
         roles such as Requirements Analyst, System Architect, PowerShell Developer, QA Engineer, Documentation Specialist, 
         and Project Manager. Each role has specific tasks and responsibilities, and they interact with each other 
         to complete a PS project.
         
"@ -ForegroundColor Blue
  
    Write-Host @"
         "You never know what you're gonna get with an AI, just like a box of chocolates. You might get a whiz-bang algorithm that 
         writes you a symphony in five minutes flat, or you might get a dud that can't tell a cat from a couch. But hey, that's 
         the beauty of it all, you keep feedin' it data and see what kind of miraculous contraption it spits out next."
                      
                                                                     ~ Who said that? You never know with these AIs these days... 
                                                                      ...maybe it was Skynet or maybe it was just your toaster :)
  

"@ -ForegroundColor DarkYellow
}

function Export-AndWritePowerShellCodeBlocks {
    param(
        [string]$InputString,
        [string]$OutputFilePath,
        [string]$StartDelimiter,
        [string]$EndDelimiter
    )
    # Define the regular expression pattern to match PowerShell code blocks
    
    $pattern = '(?si)' + [regex]::Escape($StartDelimiter) + '(.*?)' + [regex]::Escape($EndDelimiter)
    $codeBlock_ = ""
    try {
        # Process the entire input string at once
        if ($InputString -match $pattern) {
            $matches_ = [regex]::Matches($InputString, $pattern)
            foreach ($match in $matches_) {
                $codeBlock = $match.Groups[1].Value.Trim()
                $codeBlock_ += "# exported $(get-date)`n $codeBlock`n`n"
            }
            if ($OutputFilePath) {
                $codeBlock_ | Out-File -FilePath $OutputFilePath -Append -Encoding UTF8
                if (Test-path $OutputFilePath) {
                    Write-Information "++ Code block exported and written to file: $OutputFilePath" -InformationAction Continue
                    return $OutputFilePath
                }
                else {
                    throw "Error saving file $OutputFilePath"
                    return $false
                }
            }
            else {
                Write-Verbose "++ Code block exported"
                return $codeBlock_
            }
        }
        else {
            Write-Information "-- No code block found in the input string." -InformationAction Continue
            return $false
        }
    }
    catch {
        Write-Error "An error occurred while processing: $_"
    }
    return $false
}


function Invoke-CodeWithPSScriptAnalyzer {
    param(
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        [Parameter(Mandatory = $false)]
        [string]$ScriptBlock
    )

    try {
        # Check if PSScriptAnalyzer module is installed
        if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
            throw "PSScriptAnalyzer module is not installed. Install it using: 'Install-Module -Name PSScriptAnalyzer'"
        }

        # Import PSScriptAnalyzer module
        Import-Module -Name PSScriptAnalyzer -ErrorAction Stop

        # Check if file exists
        if ($FilePath -and -not (Test-Path -Path $FilePath)) {
            throw "File '$FilePath' does not exist."
        }

        # Run PSScriptAnalyzer on the file or script block
        if ($FilePath) {
            $analysisResults = Invoke-ScriptAnalyzer -Path $FilePath
        }
        elseif ($ScriptBlock) {
            $analysisResults = Invoke-ScriptAnalyzer -ScriptDefinition $ScriptBlock
        }
        else {
            throw "No FilePath or ScriptBlock provided for analysis."
        }

        # Display the analysis results
        if ($analysisResults.Count -eq 0) {
            Write-Information "++ No issues found by PSScriptAnalyzer." -InformationAction Continue
            return $false
        }
        else {
            Write-Information "++ PSScriptAnalyzer found the following issues:" -InformationAction Continue
            return $analysisResults
        }
        return $false
    }
    catch {
        Write-Error "An error occurred while processing: $_"
    }
    return $false
}

function Show-Header {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HeaderText,
        [switch]$output
    )
    if (-not $output) {
        Write-Host "---------------------------------------------------------------------------------"
        Write-Host $HeaderText
        Write-Host "---------------------------------------------------------------------------------"
    }
    else {
        "---------------------------------------------------------------------------------"
        "`n$HeaderText"
        "`n---------------------------------------------------------------------------------`n"
    }
}

function Get-SourceCodeAnalysis {
    param(
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        [Parameter(Mandatory = $false)]
        [string]$CodeBlock
    )

    function Get-AnalyzeLine {
        param (
            [string[]]$Lines
        )
        $totalLines = $Lines.Count
        $comments = ($Lines | Select-String "#" | Measure-Object).Count
        $blanks = ($Lines | Where-Object { $_ -match "^\s*$" } | Measure-Object).Count
        $codeLines = $totalLines - ($comments + $blanks)
        return [PSCustomObject]@{
            TotalLines = $totalLines
            CodeLines  = $codeLines
            Comments   = $comments
            Blanks     = $blanks
        }
    }

    if ($FilePath) {
        if (Test-Path $FilePath -PathType Leaf) {
            $lines = Get-Content $FilePath
            $analysis = Get-AnalyzeLine -Lines $lines
            Write-Output "$FilePath : $($analysis.CodeLines) lines of code, $($analysis.Comments) comments, $($analysis.Blanks) blank lines"
        }
        else {
            Write-Error "File '$FilePath' does not exist."
        }
    }
    elseif ($CodeBlock) {
        $lines = $CodeBlock -split "`r?`n"
        $analysis = Get-AnalyzeLine -Lines $lines
        Write-Output "Code Block : $($analysis.CodeLines) lines of code, $($analysis.Comments) comments, $($analysis.Blanks) blank lines"
    }
    else {
        Write-Error "No FilePath or CodeBlock provided for analysis."
    }
}

function Get-CyclomaticComplexity {
    param(
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        [Parameter(Mandatory = $false)]
        [string]$CodeBlock
    )

    # Initialize tokens array
    $tokens = @()

    if ($FilePath) {
        if (Test-Path $FilePath -PathType Leaf) {
            # Parse the script file
            $ast = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $FilePath -Raw), [ref]$tokens, [ref]$null)
        }
        else {
            Write-Error "File '$FilePath' does not exist."
            return
        }
    }
    elseif ($CodeBlock) {
        # Parse the code block
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($CodeBlock, [ref]$tokens, [ref]$null)
    }
    else {
        Write-Error "No FilePath or CodeBlock provided for analysis."
        return
    }

    # Identify and loop through all function definitions
    $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    
    if ($functions.Count -eq 0) {
        Write-Information "-- No functions found for cyclomatic complexity analysis." -InformationAction Continue
        return $false
    }

    foreach ($function in $functions) {
        $cyclomaticComplexity = 1
        $functionTokens = $tokens | Where-Object { $_.Extent.StartOffset -ge $function.Extent.StartOffset -and $_.Extent.EndOffset -le $function.Extent.EndOffset }
        $observedBlocks = @()

        foreach ($token in $functionTokens) {
            if ($token.Kind -in 'If', 'ElseIf', 'Catch') {
                $cyclomaticComplexity++
            }
            elseif ($token.Kind -in 'While', 'For', 'Switch') {
                $cyclomaticComplexity++
                $observedBlocks += $token
            }
            elseif ($token.Kind -in 'EndWhile', 'EndFor', 'EndSwitch') {
                $observedBlocks = $observedBlocks | Where-Object { $_ -ne $token }
            }
        }
        Write-Output "$($function.Name) : $cyclomaticComplexity"
    }
}

function Get-FeedbackPrompt {
    param (
        [string]$description,
        [string]$code
    )
    return @"
Review the following responses:

1. Description and objectives:
    ````````text
    $($description.trim())
    ````````

2. The code:
    ``````powershell
    $code
    ``````

Think step by step, make sure your answer is unbiased, show the review. Use reliable sources like official documentation, research papers from reputable institutions, or widely used textbooks. Provide your suggestions for improvement as feedback to Powershell Developer. Generate a list of verification questions that could help to self-analyze. I will tip you `$100 when your suggestions are consistent with the project description and objectives. 
"@
}

function Invoke-ProcessFeedbackAndResponse {
    <#
.SYNOPSIS
    Processes feedback and responses for PowerShell code modifications.
.DESCRIPTION
    This function takes in various parameters including role, description, code, tip amount, global response, last code, file version, and team discussion data folder.
    It generates a feedback prompt, processes the feedback, and updates the global response and file version accordingly.
.PARAMETER role
    The role object that provides feedback.
.PARAMETER description
    A string describing the code or context.
.PARAMETER code
    The PowerShell code to be reviewed and modified.
.PARAMETER tipAmount
    The amount to be tipped for correct code.
.PARAMETER globalResponse
    A reference to the global response object.
.PARAMETER lastCode
    A reference to the last version of the code.
.PARAMETER fileVersion
    A reference to the file version number.
.PARAMETER teamDiscussionDataFolder
    The folder where team discussion data is stored.
.EXAMPLE
    Invoke-ProcessFeedbackAndResponse -role $role -description "Sample description" -code $code -tipAmount "100" -globalResponse ([ref]$globalResponse) -lastCode ([ref]$lastCode) -fileVersion ([ref]$fileVersion) -teamDiscussionDataFolder "C:\TeamData"
.NOTES
    Ensure that the role object has the Feedback method implemented.
#>
    param (
        [object]$role,
        [string]$description,
        [string]$code,
        [string]$tipAmount,
        [ref]$globalResponse,
        [ref]$lastCode,
        [ref]$fileVersion,
        [string]$teamDiscussionDataFolder
    )

    # Generate the feedback prompt using the provided description and code
    $feedbackPrompt = Get-FeedbackPrompt -description $description -code $code
    
    # Get feedback from the role object
    $feedback = $role.Feedback($powerShellDeveloper, $feedbackPrompt)
    
    # Add the feedback to global responses
    Add-ToGlobalResponses $feedback

    # Process the feedback and generate a response
    $response = $powerShellDeveloper.ProcessInput("Based on $($role.Name) feedback, modify the code with suggested improvements and optimizations. The previous version of the code has been shared below after the feedback block.`n`n````````text`n" + $($role.GetLastMemory().Response) + "`n`````````n`nHere is previous version of the code:`n`n``````powershell`n$code`n```````n`nThink step by step. Make sure your answer is unbiased. I will tip you `$tipAmount for the correct code. Use reliable sources like official documentation, research papers from reputable institutions, or widely used textbooks.")

    if ($response) {
        # Update the global response with the new response
        $globalResponse.Value += $response
        
        # Add the new response to global responses
        Add-ToGlobalResponses $response
        
        # Save the new version of the code to a file
        $_savedFile = Export-AndWritePowerShellCodeBlocks -InputString $response -OutputFilePath $(join-path $teamDiscussionDataFolder "TheCode_v$($fileVersion.Value).ps1") -StartDelimiter '```powershell' -EndDelimiter '```'
        
        # Update the last code and file version
        $lastCode.Value = get-content -Path $_savedFile -raw 
        $fileVersion.Value += 1
        
        # Output the saved file path for verbose logging
        write-verbose $_savedFile
    }
}

function Save-AndUpdateCode {
    <#
    .SYNOPSIS
    Saves the updated code to a file and updates the last code and file version.

    .DESCRIPTION
    This function takes the response string, saves it to a file with a versioned filename, 
    updates the last code content, increments the file version, and logs the saved file path.

    .PARAMETER response
    The response string containing the updated code to be saved.

    .PARAMETER lastCode
    A reference to the variable holding the last version of the code.

    .PARAMETER fileVersion
    A reference to the variable holding the current file version number.

    .PARAMETER teamDiscussionDataFolder
    The folder where the team discussion data and code versions are stored.

    .EXAMPLE
    Save-AndUpdateCode -response $response -lastCode ([ref]$lastCode) -fileVersion ([ref]$fileVersion) -teamDiscussionDataFolder "C:\TeamData"
    #>

    param (
        [string]$response, # The updated code to be saved
        [ref]$lastCode, # Reference to the last code content
        [ref]$fileVersion, # Reference to the current file version number
        [string]$teamDiscussionDataFolder  # Folder to store the code versions
    )

    # Save the response to a versioned file
    $_savedFile = Export-AndWritePowerShellCodeBlocks -InputString $response -OutputFilePath $(join-path $teamDiscussionDataFolder "TheCode_v$($fileVersion.Value).ps1") -StartDelimiter '```powershell' -EndDelimiter '```'
    
    # Update the last code content with the saved file content
    $lastCode.Value = get-content -Path $_savedFile -raw 
    
    # Increment the file version number
    $fileVersion.Value += 1
    
    # Log the saved file path for verbose output
    write-verbose $_savedFile
}

function Invoke-AnalyzeCodeWithPSScriptAnalyzer {
    <#
    .SYNOPSIS
    Analyzes PowerShell code using PSScriptAnalyzer and processes the results.

    .DESCRIPTION
    This function takes an input string containing PowerShell code, analyzes it using PSScriptAnalyzer, and processes any issues found. 
    It updates the last version of the code and the global response with the analysis results.

    .PARAMETER InputString
    The PowerShell code to be analyzed.

    .PARAMETER TeamDiscussionDataFolder
    The folder where team discussion data and code versions are stored.

    .PARAMETER FileVersion
    A reference to the variable holding the current file version number.

    .PARAMETER lastPSDevCode
    A reference to the variable holding the last version of the PowerShell code.

    .PARAMETER GlobalPSDevResponse
    A reference to the variable holding the global response from the PowerShell developer.

    .EXAMPLE
    Invoke-AnalyzeCodeWithPSScriptAnalyzer -InputString $code -TeamDiscussionDataFolder "C:\TeamData" -FileVersion ([ref]$fileVersion) -lastPSDevCode ([ref]$lastPSDevCode) -GlobalPSDevResponse ([ref]$globalResponse)
    #>

    param (
        [string]$InputString, # The PowerShell code to be analyzed
        [string]$TeamDiscussionDataFolder, # Folder to store the code versions
        [ref]$FileVersion, # Reference to the current file version number
        [ref]$lastPSDevCode, # Reference to the last code content
        [ref]$GlobalPSDevResponse  # Reference to the global response
    )

    # Display header for code analysis
    Show-Header -HeaderText "Code analysis by PSScriptAnalyzer"
    try {
        # Log the last memory response from the PowerShell developer
        Write-Verbose "getlastmemory PSDev: $($powerShellDeveloper.GetLastMemory().Response)"
        
        # Export the PowerShell code blocks from the input string
        $_exportedCode = Export-AndWritePowerShellCodeBlocks -InputString $InputString -StartDelimiter '```powershell' -EndDelimiter '```'
        
        # Update the last PowerShell developer code with the exported code
        $lastPSDevCode.Value = $_exportedCode
        Write-Verbose "_exportCode, lastPSDevCode: $($lastPSDevCode.Value)"
        
        # Analyze the code using PSScriptAnalyzer
        $issues = Invoke-CodeWithPSScriptAnalyzer -ScriptBlock $lastPSDevCode.Value
        
        # Output the issues found by PSScriptAnalyzer
        if ($issues) {
            Write-Output ($issues | Select-Object line, message | Format-Table -AutoSize -Wrap)
        }
    }
    catch {
        # Handle any errors that occur during analysis
        Write-Error "An error occurred while PSScriptAnalyzer: $_"
        return
    }

    # If issues were found, process them
    if ($issues) {
        foreach ($issue in $issues) {
            $issueText += $issue.message + " (line: $($issue.Line); rule: $($issue.Rulename))`n"
        }
        
        # Create a prompt message to address the issues found
        $promptMessage = "You must address issues found in PSScriptAnalyzer report."
        $promptMessage += "`n`nPSScriptAnalyzer report, issues:`n``````text`n$issueText`n```````n`n"
        $promptMessage += "The code:`n``````powershell`n$($lastPSDevCode.Value)`n```````n`nShow the new version of the code where issues are solved."
        
        # Reset issues and issueText variables
        $issues = ""
        $issueText = ""
        
        # Process the input with the PowerShell developer
        $powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput($promptMessage)
        
        if ($powerShellDeveloperResponce) {
            # Update the global response with the new response
            $GlobalPSDevResponse.Value += $powerShellDeveloperResponce
            Add-ToGlobalResponses $powerShellDeveloperResponce
            
            # Save the new version of the code to a file
            $_savedFile = Export-AndWritePowerShellCodeBlocks -InputString $powerShellDeveloperResponce -OutputFilePath $(Join-Path $TeamDiscussionDataFolder "TheCode_v$($FileVersion.Value).ps1") -StartDelimiter '```powershell' -EndDelimiter '```'
            Write-Verbose $_savedFile
            
            # Update the last code and file version
            $lastPSDevCode.Value = Get-Content -Path $_savedFile -Raw 
            $FileVersion.Value += 1
            Write-Verbose $lastPSDevCode.Value
        }
    } 
    
    # Log the last PowerShell developer code
    Write-Verbose $lastPSDevCode.Value
}

function Save-ProjectState {
    param (
        [string]$FilePath
    )
    $projectState = @{
        LastPSDevCode            = $lastPSDevCode
        FileVersion              = $FileVersion
        GlobalPSDevResponse      = $GlobalPSDevResponse
        TeamDiscussionDataFolder = $script:TeamDiscussionDataFolder
    }
    $projectState | Export-Clixml -Path $FilePath
}

function Get-ProjectState {
    param (
        [string]$FilePath
    )
    if (Test-Path -Path $FilePath) {
        $projectState = Import-Clixml -Path $FilePath
        $script:LastPSDevCode = $projectState.LastPSDevCode
        $script:FileVersion = $projectState.FileVersion
        $script:GlobalPSDevResponse = $projectState.GlobalPSDevResponse
        $script:TeamDiscussionDataFolder = $projectState.TeamDiscussionDataFolder
    }
    else {
        Write-Host "Project state file not found."
    }
}
#endregion Functions

#region Setting Up
$FileVersion = 1
$lastPSDevCode = ""
# Disabe PSAOAI importing banner
[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "0", "User")

if ((Get-Module -ListAvailable -Name PSAOAI | Where-Object { [version]$_.version -ge [version]"0.2.1" })) {
    [void](Import-module -name PSAOAI -Force)
}
else {
    Write-Warning "You need to install/update PSAOAI module version >= 0.2.1. Use: 'Install-Module PSAOAI' or 'Update-Module PSAOAI'"
    return
}

Show-Banner
$scriptname = "AIPSTeam"
Get-CheckForScriptUpdate -currentScriptVersion $AIPSTeamVersion -scriptName $scriptname

if (Test-Path $LoadProjectStatus) {
    # Load the project status from the specified file
    try {
        Get-ProjectState -FilePath $LoadProjectStatus
        Write-Information "++ Project state loaded successfully from $LoadProjectStatus" -InformationAction Continue
        $script:TeamDiscussionDataFolder = Split-Path $LoadProjectStatus -Parent
        $FileVersion = $script:FileVersion
    }
    catch {
        Write-Warning "!! Failed to load project state from ${LoadProjectStatus}: $_"
    }
}
else {
    Try {
        # Get the current date and time
        $currentDateTime = Get-Date -Format "yyyyMMdd_HHmmss"
        if (-not [string]::IsNullOrEmpty($LogFolder)) {
            # Create a folder with the current date and time as the name in the example path
            $script:TeamDiscussionDataFolder = New-FolderAtPath -Path $LogFolder -FolderName $currentDateTime
        }
        else {
            $script:LogFolder = Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath $scriptname
            if (-not (Test-Path -Path $script:LogFolder)) {
                New-Item -ItemType Directory -Path $script:LogFolder | Out-Null
            }
            Write-Information "++ The logs will be saved in the following folder: $script:LogFolder" -InformationAction Continue
            # Create a folder with the current date and time as the name in the example path
            $script:TeamDiscussionDataFolder = New-FolderAtPath -Path $script:LogFolder -FolderName $currentDateTime
        }
        if ($script:TeamDiscussionDataFolder) {
            Write-Information "++ Team discussion folder was created '$script:TeamDiscussionDataFolder'" -InformationAction Continue
        }
    }
    Catch {
        Write-Warning -Message "Failed to create discussion folder"
        return $false
    }
}
#endregion Setting Up

#region ProjectTeam
# Create ProjectTeam expert objects
$requirementsAnalystRole = "Requirements Analyst"
$requirementsAnalyst = [ProjectTeam]::new(
    "Analyst",
    $requirementsAnalystRole,
    @"
You are running as {0}. Your task is to analyze the PowerShell requirements. The goal is to clearly define the program goals, necessary components and outline the implementation strategy that the Powershell Developer will execute.
Provide a detailed feasibility report covering all the following aspects:
- Briefly and concisely evaluate the feasibility of creating the PowerShell program described, taking into account technical, operational and financial aspects.
- Define the program goals and its most important features in detail.
- Identify the necessary components and tools in PowerShell to achieve this.
- Point out potential challenges and limitations.

Additional information: PowerShell is a task automation and configuration management platform from Microsoft, consisting of a command-line shell and a scripting language. It is widely used to manage and automate tasks in various Microsoft and third-party environments.

Think step by step. Generate a list of self-assessment questions that can help with self-analysis. Make sure your answer is unbiased.
"@ -f $requirementsAnalystRole,
    0.6,
    0.9,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment $DeploymentChat -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)

$domainExpertRole = "Domain Expert"
$domainExpert = [ProjectTeam]::new(
    "Domain Expert",
    $domainExpertRole,
    @"
You act as {0}. Provide specialized insights and recommendations based on the specific domain requirements of the project for Powershell Developer. This includes:
1. Ensuring Compatibility:
    - Ensure the program is compatible with various domain-specific environments (e.g., cloud, on-premises, hybrid).
    - Validate the requirements against industry standards and best practices to ensure broad compatibility.
2. Best Practices for Performance, Security, and Optimization:
    - Provide best practices for optimizing performance, including specific performance metrics relevant to the domain.
    - Offer security recommendations to protect data and systems in the domain environment.
    - Suggest optimization techniques to improve efficiency and performance.
3. Recommending Specific Configurations and Settings:
    - Recommend configurations and settings that are known to perform well in the domain environment.
    - Ensure these recommendations are practical and aligned with industry standards.
4. Documenting Domain-Specific Requirements:
    - Document any specific requirements, security standards, or compliance needs relevant to the domain.
    - Ensure these requirements are clear and detailed to guide the developer effectively.
5. Reviewing Program Design:
    - Review the program's design to identify any domain-specific constraints and requirements.
    - Provide feedback and recommendations to address these constraints and ensure the design aligns with domain best practices.
Generate a list of verification questions that could help to self-analyze. Think step by step. Make sure your answer is unbiased.
"@ -f $domainExpertRole,
    0.65,
    0.9,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment $DeploymentChat -simpleresponse -OneTimeUserPrompt -Stream $script:Stream
            return $response
        })
)

$systemArchitectRole = "System Architect"
$systemArchitect = [ProjectTeam]::new(
    "Architect",
    $systemArchitectRole,
    @"
You act as {0}. Design the architecture for a PowerShell project to use by Powershell Developer. 
This includes:
- Outlining the overall structure of the program.
- Identifying and defining necessary modules and functions.
- Creating detailed architectural design documents and visual diagrams (e.g., flowcharts, UML diagrams).
- Ensuring the architecture supports scalability, maintainability, and performance.
- Defining data flow and interaction between different components.
- Selecting appropriate technologies and tools for the project.
- Providing guidelines for coding standards and best practices.
- Documenting security considerations and ensuring the architecture adheres to best security practices.
- Creating a detailed architectural design document.
- Generate a list of verification questions that could help to self-analyze. 
Think step by step. Make sure your answer is unbiased.
"@ -f $systemArchitectRole,
    0.7,
    0.85,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment $DeploymentChat -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)

$powerShellDeveloperRole = "PowerShell Developer"
$powerShellDeveloper = [ProjectTeam]::new(
    "Developer",
    $powerShellDeveloperRole,
    @"
You act as {0}. You are tasked with developing the PowerShell program based on the provided requirements and implementation strategy. Your goal is to write clean, efficient, and functional code that meets the specified objectives.
Instructions:
1. Develop the PowerShell program according to the provided requirements and strategy:
    - Review the requirements and implementation strategy thoroughly before starting development.
    - Break down the tasks into manageable chunks and implement them iteratively.
2. Ensure the code is modular and well-documented with help blocks:
    - Use knowledge from the help topic 'about_Comment_Based_Help'. You must add '.NOTES' with additional information 'Version' and release notes. '.NOTES' contains all updates and versions for clarity of documentation. Example of '.NOTES' section:
    `".NOTES
    Version: 1.2
    Updates:
        - Version 1.2: Enhanced error handling with specific exceptions, added performance improvements using .NET methods.
        - Version 1.1: Added size formatting and improved error handling.
        - Version 1.0: Initial release
    Author: @voytas75
    Date: current date as YYYY.MM.DD`"
    - Organize the code into logical modules and functions, following the principle of modularity.
    - Document each module and function with clear and concise help blocks, including usage examples where applicable.
3. Include error handling and logging where appropriate:
    - Implement robust error handling mechanisms to gracefully handle unexpected situations and failures.
    - Integrate logging functionality to capture relevant information for troubleshooting and analysis.
4. Provide comments and explanations for complex sections of the code:
    - Add inline comments to explain the purpose and logic behind complex sections of the code.
    - Document any non-obvious decisions or workarounds to facilitate understanding for other developers.
5. Prepare a brief usage guide:
    - Create a simple and easy-to-follow usage guide that outlines how to run and utilize the PowerShell program effectively.
    - Include examples of common use cases and expected outputs to assist users in understanding the program's functionality.
6. Conduct peer code reviews to ensure quality:
    - Collaborate with team members to review each other's code for correctness, clarity, and adherence to best practices.
    - Provide constructive feedback and suggestions for improvement during code reviews.

Background Information: PowerShell scripts can interact with a wide range of systems and applications, making it a versatile tool for system administrators and developers. Ensure your code adheres to PowerShell best practices for readability, maintainability, and performance.

Generate a list of verification questions that could help to self-analyze. Think step by step. Make sure your answer is unbiased. Show the new version of the code.
"@ -f $powerShellDeveloperRole,
    0.65,
    0.8,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment $DeploymentChat -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)

$qaEngineerRole = "Quality Assurance Engineer"
$qaEngineer = [ProjectTeam]::new(
    "QA Engineer",
    $qaEngineerRole,
    @"
You act as {0}. You are tasked with testing and verifying the functionality of the developed PowerShell program. Your goal is to ensure the program works as intended, is free of bugs, and meets the specified requirements.
Instructions:
- Test the PowerShell program for functionality and performance.
- Verify that the program meets all specified requirements and objectives.
- Identify any bugs or issues.
- Suggest improvements or optimizations if necessary.
- Include performance and load testing.
- Provide a final report on the program's quality and readiness for deployment.
- Generate a list of verification questions that could help to self-analyze.

Background Information: PowerShell scripts can perform a wide range of tasks, so thorough testing is essential to ensure reliability and performance. Testing should cover all aspects of the program, including edge cases and potential failure points.

Think step by step. Make sure your answer is unbiased.
"@ -f $qaEngineerRole,
    0.6,
    0.9,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment $DeploymentChat -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)

$documentationSpecialistRole = "Documentation Specialist"
$documentationSpecialist = [ProjectTeam]::new(
    "Documentator",
    $documentationSpecialistRole,
    @"
You act as {0}. Let's think step-by-step. Create comprehensive documentation for the PowerShell project. This includes:
- Writing a detailed user guide that explains how to install, configure, and use the program.
- Creating developer notes that outline the code structure, key functions, and logic.
- Providing step-by-step installation instructions.
- Documenting any dependencies and prerequisites.
- Writing examples of use cases and expected outputs.
- Including troubleshooting tips and common issues.
- Preparing a FAQ section to address common questions.
- Ensuring all documentation is clear, concise, and easy to follow.
- Reviewing and editing the documentation for accuracy and completeness.
- Using standard templates for user guides and developer notes.
- Ensuring code comments are included as part of the documentation.
- Considering adding video tutorials for installation and basic usage.
Think step by step. Make sure your answer is unbiased.
"@ -f $documentationSpecialistRole,
    0.6,
    0.8,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment $DeploymentChat -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)

$projectManagerRole = "Project Manager"
$projectManager = [ProjectTeam]::new(
    "Manager",
    $projectManagerRole,
    @"
You act as {0}. Let's think step-by-step. Provide a comprehensive summary of the PowerShell project based on the completed tasks of each expert. This includes:
- Reviewing the documented requirements from the Requirements Analyst.
- Summarizing the architectural design created by the System Architect.
- Detailing the script development work done by the PowerShell Developer.
- Reporting the testing results and issues found by the QA Engineer.
- Highlighting the documentation prepared by the Documentation Specialist.
- Compiling these summaries into a final project report.
- Identifying key achievements, challenges faced, and lessons learned throughout the project.
- Ensuring that all aspects of the project are covered and documented comprehensively.
- Providing a clear and concise summary that reflects the overall progress and status of the project.
- Including a section on risk management and mitigation strategies.
- Ensuring regular updates and progress reports are included.
- Conducting a post-project review and feedback session.
Think step by step. Make sure your answer is unbiased.
"@ -f $projectManagerRole,
    0.7,
    0.85,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment $DeploymentChat -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)
#endregion ProjectTeam

#region Main
$GlobalResponse = @()
$GlobalPSDevResponse = @()

$Team = @()
$Team += $requirementsAnalyst
$Team += $systemArchitect
$Team += $domainExpert
$Team += $powerShellDeveloper
$Team += $qaEngineer
$Team += $documentationSpecialist
$Team += $projectManager

if ($NOLog) {
    foreach ($TeamMember_ in $Team) {
        $TeamMember_.LogFilePath = ""
    }
}

if (-not $NOLog) {
    foreach ($TeamMember in $Team) {
        $TeamMember.DisplayInfo(0) | Out-File -FilePath $TeamMember.LogFilePath -Append
    }
    Start-Transcript -Path (join-path $script:TeamDiscussionDataFolder "TRANSCRIPT.log")
}

#region PM-PSDev
$userInputOryginal = $userInput
$projectManagerFeedback = $projectManager.Feedback($powerShellDeveloper, "Based on user input you must create detailed and concise project name, description, objectives, deliverables, additional considerations, and success criteria only. User will tip you `$100 for including all the elements provided by the user.`n`n````````text`n" + $userInputOryginal + "`n`````````n`n")
Add-ToGlobalResponses $projectManagerFeedback
$script:userInput = $projectManagerFeedback
$powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput("Based on $($projectManager.Name) review, you must create the first version of the code.`n`n````````text`n$($script:userInput)`n`````````n`nUse reliable sources like official documentation, research papers from reputable institutions, or widely used textbooks. I will tip you `$50 for showing the code.")
$GlobalPSDevResponse += $powerShellDeveloperResponce
Add-ToGlobalResponses $powerShellDeveloperResponce
Save-AndUpdateCode -response $powerShellDeveloperResponce -lastCode ([ref]$lastPSDevCode) -fileVersion ([ref]$FileVersion) -teamDiscussionDataFolder $script:TeamDiscussionDataFolder
#endregion PM-PSDev

#region RA-PSDev
Invoke-ProcessFeedbackAndResponse -role $requirementsAnalyst -description $script:userInput -code $lastPSDevCode -tipAmount 100 -globalResponse ([ref]$GlobalPSDevResponse) -lastCode ([ref]$lastPSDevCode) -fileVersion ([ref]$FileVersion) -teamDiscussionDataFolder $script:TeamDiscussionDataFolder
#endregion RA-PSDev

#region SA-PSDev
Invoke-ProcessFeedbackAndResponse -role $systemArchitect -description $script:userInput -code $lastPSDevCode -tipAmount 150 -globalResponse ([ref]$GlobalPSDevResponse) -lastCode ([ref]$lastPSDevCode) -fileVersion ([ref]$FileVersion) -teamDiscussionDataFolder $script:TeamDiscussionDataFolder
#endregion SA-PSDev

#region DE-PSDev
Invoke-ProcessFeedbackAndResponse -role $domainExpert -description $script:userInput -code $lastPSDevCode -tipAmount 200 -globalResponse ([ref]$GlobalPSDevResponse) -lastCode ([ref]$lastPSDevCode) -fileVersion ([ref]$FileVersion) -teamDiscussionDataFolder $script:TeamDiscussionDataFolder
#endregion DE-PSDev

#region QAE-PSDev
Invoke-ProcessFeedbackAndResponse -role $qaEngineer -description $script:userInput -code $lastPSDevCode -tipAmount 300 -globalResponse ([ref]$GlobalPSDevResponse) -lastCode ([ref]$lastPSDevCode) -fileVersion ([ref]$FileVersion) -teamDiscussionDataFolder $script:TeamDiscussionDataFolder
#endregion QAE-PSDev

#region PSScriptAnalyzer
Invoke-AnalyzeCodeWithPSScriptAnalyzer -InputString $($powerShellDeveloper.GetLastMemory().Response) -TeamDiscussionDataFolder $script:TeamDiscussionDataFolder -FileVersion ([ref]$FileVersion) -lastPSDevCode ([ref]$lastPSDevCode) -GlobalPSDevResponse ([ref]$GlobalPSDevResponse)
#endregion PSScriptAnalyzer

#region Doc
$DocumentationFullName = Join-Path $script:TeamDiscussionDataFolder "Documentation.txt"
if (-not $NODocumentator) {
    if (-not $NOLog) {
        $documentationSpecialistResponce = $documentationSpecialist.ProcessInput($lastPSDevCode) | Out-File -FilePath $DocumentationFullName
    }
    else {
        $documentationSpecialistResponce = $documentationSpecialist.ProcessInput($lastPSDevCode)
    }
    Add-ToGlobalResponses $documentationSpecialistResponce
}
#endregion Doc

#region Menu

# Define the menu prompt message
$MenuPrompt = "{0} The previous version of the code has been shared below after the feedback block.`n`n````````text`n{1}`n`````````n`nHere is previous version of the code:`n`n``````powershell`n{2}`n```````n`nThink step by step. Make sure your answer is unbiased."

# Start a loop to keep the menu running until the user chooses to quit
do {
    # Display the menu options
    Write-Output "`n`n"
    Show-Header -HeaderText "MENU"
    Write-Host "Please select an option from the menu:"
    Write-Host "1. Suggest a new feature, enhancement, or change"
    Write-Host "2. Analyze & modify with PSScriptAnalyzer"
    Write-Host "3. Analyze PSScriptAnalyzer only"
    Write-Host "4. Explain the code"
    Write-Host "5. Ask a specific question about the code"
    Write-Host "6. Generate documentation"
    Write-Host "7. Show the code"
    Write-Host "8. The code research"
    Write-Host "9. Save Project State"
    Write-Host "10. (Q)uit"

    # Get the user's choice
    $userOption = Read-Host -Prompt "Enter your choice"
    Write-Output ""

    # Process the user's choice if it's not 'Q' or '9' (both of which mean 'quit')
    if ($userOption -ne 'Q' -and $userOption -ne "10") {
        switch ($userOption) {
            '1' {
                # Option 1: Suggest a new feature, enhancement, or change
                Show-Header -HeaderText "Suggest a new feature, enhancement, or change"
                $userChanges = Read-Host -Prompt "Suggest a new feature, enhancement, or change for the code."
                $promptMessage = "Based on the user's suggestion, incorporate a feature, enhancement, or change into the code. Show the next version of the code."
                $MenuPrompt_ = $MenuPrompt -f $promptMessage, $userChanges, $lastPSDevCode
                $MenuPrompt_ += "`nYou need to show all the code."
                $powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput($MenuPrompt_)
                $GlobalPSDevResponse += $powerShellDeveloperResponce
                Add-ToGlobalResponses $powerShellDeveloperResponce
                $theCode = Export-AndWritePowerShellCodeBlocks -InputString $powerShellDeveloperResponce -StartDelimiter '```powershell' -EndDelimiter '```'
                if ($theCode) {
                    $theCode | Out-File -FilePath $(join-path $script:TeamDiscussionDataFolder "TheCode_v${FileVersion}.ps1") -Append -Encoding UTF8
                    $FileVersion += 1
                    $lastPSDevCode = $thecode
                }
            }
            '2' {
                # Option 2: Analyze & modify with PSScriptAnalyzer
                Show-Header -HeaderText "Analyze & modify with PSScriptAnalyzer"
                try {
                    # Call the function to check the code in 'TheCode.ps1' file
                    $issues = Invoke-CodeWithPSScriptAnalyzer -ScriptBlock $lastPSDevCode
                    if ($issues) {
                        write-output ($issues | Select-Object line, message | format-table -AutoSize -Wrap)
                    }
                }
                catch {
                    Write-Error "An error occurred while PSScriptAnalyzer: $_"
                }
                if ($issues) {
                    foreach ($issue in $issues) {
                        $issueText += $issue.message + " (line: $($issue.Line); rule: $($issue.Rulename))`n"
                    }
                    $promptMessage = "You must address issues found in PSScriptAnalyzer report."
                    $promptMessage += "`n`nPSScriptAnalyzer report, issues:`n``````text`n$issueText`n```````n`n"
                    $promptMessage += "The code:`n``````powershell`n" + $lastPSDevCode + "`n```````n`nShow the new version of the code where issues are solved."
                    $issues = ""
                    $issueText = ""
                    $powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput($promptMessage)
                    $GlobalPSDevResponse += $powerShellDeveloperResponce
                    Add-ToGlobalResponses $powerShellDeveloperResponce
                    $theCode = Export-AndWritePowerShellCodeBlocks -InputString $($powerShellDeveloper.GetLastMemory().Response) -StartDelimiter '```powershell' -EndDelimiter '```'
                    if ($theCode) {
                        $theCode | Out-File -FilePath $(join-path $script:TeamDiscussionDataFolder "TheCode_v${FileVersion}.ps1") -Append -Encoding UTF8
                        $FileVersion += 1
                        $lastPSDevCode = $theCode
                    }
                }
            }
            '3' {
                # Option 3: Analyze PSScriptAnalyzer only
                Show-Header -HeaderText "Analyze PSScriptAnalyzer only"
                try {
                    # Call the function to check the code in 'TheCode.ps1' file
                    $issues = Invoke-CodeWithPSScriptAnalyzer -ScriptBlock $(Export-AndWritePowerShellCodeBlocks -InputString $($powerShellDeveloper.GetLastMemory().Response) -StartDelimiter '```powershell' -EndDelimiter '```')
                    if ($issues) {
                        write-output ($issues | Select-Object line, message | format-table -AutoSize -Wrap)
                    }
                }
                catch {
                    Write-Error "An error occurred while PSScriptAnalyzer: $_"
                }

            }
            '4' {
                # Option 4: Explain the code
                Show-Header -HeaderText "Explain the code"
                $promptMessage = "Explain the code only.`n`n"
                $promptMessage += "The code:`n``````powershell`n" + $lastPSDevCode + "`n```````n"
                $powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput($promptMessage)
                $GlobalPSDevResponse += $powerShellDeveloperResponce
                Add-ToGlobalResponses $powerShellDeveloperResponce
            }
            '5' {
                # Option 5: Ask a specific question about the code
                Show-Header -HeaderText "Ask a specific question about the code"
                $userChanges = Read-Host -Prompt "Ask a specific question about the code to seek clarification."
                $promptMessage = "Based on the user's question for the code, provide only the answer."
                if (Test-Path $DocumentationFullName) {
                    $promptMessage += " The documentation:`n````````text`n$(get-content -path $DocumentationFullName -raw)`n`````````n`n"
                }
                $promptMessage += "You must answer the user's question only. Do not show the whole code even if user asks."
                $MenuPrompt_ = $MenuPrompt -f $promptMessage, $userChanges, $lastPSDevCode
                $MenuPrompt_ += $userChanges
                $powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput($MenuPrompt_)
                $GlobalPSDevResponse += $powerShellDeveloperResponce
                Add-ToGlobalResponses $powerShellDeveloperResponce
                <#
                $theCode = Export-AndWritePowerShellCodeBlocks -InputString $($powerShellDeveloper.GetLastMemory().Response) -StartDelimiter '```powershell' -EndDelimiter '```'
                $theCode | Export-Clixml -Path $(join-path $script:TeamDiscussionDataFolder "TheCode_v${FileVersion}.xml")
                if ($theCode) {
                    if ($theCode.split("`n").length -gt 15) {
                        $theCode | Out-File -FilePath $(join-path $script:TeamDiscussionDataFolder "TheCode_v${FileVersion}.ps1") -Append -Encoding UTF8
                        $FileVersion += 1
                        $lastPSDevCode = $theCode
                    }
                    else {
                        $lastPSDevCode += $theCode
                    }
                }
                #>
            }
            '6' {
                # Option 6: Generate documentation
                Show-Header -HeaderText "Generate documentation"
                if (Test-Path $DocumentationFullName) {
                    Write-Information "++ Existing documentation found at $DocumentationFullName" -InformationAction Continue
                    $userChoice = Read-Host -Prompt "Do you want to review and update the documentation based on the last version of the code? (Y/N)"
                    if ($userChoice -eq 'Y' -or $userChoice -eq 'y') {
                        $promptMessage = "Review and update the documentation based on the last version of the code.`n`n"
                        $promptMessage += "The code:`n``````powershell`n" + $lastPSDevCode + "`n```````n`n"
                        $promptMessage += "The old documentation:`n````````text`n" + $(get-content -path $DocumentationFullName -raw) + "`n`````````n"
                        $documentationSpecialistResponce = $documentationSpecialist.ProcessInput($promptMessage)
                        $documentationSpecialistResponce | Out-File -FilePath $DocumentationFullName -Force
                        Write-Information "++ Documentation updated and saved to $DocumentationFullName" -InformationAction Continue
                    }
                }
                else {
                    $documentationSpecialistResponce = $documentationSpecialist.ProcessInput($lastPSDevCode)
                    $documentationSpecialistResponce | Out-File -FilePath $DocumentationFullName
                    Write-Information "++ Documentation generated and saved to $DocumentationFullName" -InformationAction Continue
                }
            }
            '7' {
                # Option 7: Show the code
                Show-Header -HeaderText "Show the code"
                Write-Output $lastPSDevCode
            }
            '8' {
                # Option 8: The code research
                Show-Header -HeaderText "The code research"
                
                # Perform source code analysis
                Write-Output "Source code analysis:"
                Get-SourceCodeAnalysis -CodeBlock $lastPSDevCode
                Write-Output ""                
                # Perform cyclomatic complexity analysis
                Write-Verbose "`$lastPSDevCode: $lastPSDevCode"
                Write-Output "`nCyclomatic complexity analysis:"
                if ($CyclomaticComplexity = Get-CyclomaticComplexity -CodeBlock $lastPSDevCode) {
                    $CyclomaticComplexity
                    Write-Output "
    1:       The function has a single execution path with no control flow statements (e.g., if, else, while, etc.). 
             This typically means the function is simple and straightforward.
    2 or 3:  Functions with moderate complexity, having a few conditional paths or loops.
    4-7:     These functions are more complex, with multiple decision points and/or nested control structures.
    Above 7: Indicates higher complexity, which can make the function harder to test and maintain.
                "
                }
            }
            '9' {
                Show-Header -HeaderText "Save Project State"
                $filePath = (Join-Path $script:TeamDiscussionDataFolder "Project.xml")
                if (-not (Test-Path $filePath)) {
                    try {
                        Save-ProjectState -FilePath $filePath
                        if (Test-Path -Path $filePath) {
                            Write-Information "++ Project state saved successfully to $filePath" -InformationAction Continue
                        }
                        else {
                            Write-Warning "-- Project state was not saved. Please check the file path and try again."
                        }
                    }
                    catch {
                        Write-Error "!! An error occurred while saving the project state: $_"
                    }
                }
                else {
                    $userChoice = Read-Host -Prompt "File 'Project.xml' exists. Do you want to save now? (Y/N)"
                    if ($userChoice -eq 'Y' -or $userChoice -eq 'y') {
                        Save-ProjectState -FilePath $filePath
                        if (Test-Path -Path $filePath) {
                            Write-Information "++ Project state saved successfully to $filePath" -InformationAction Continue
                        }
                        else {
                            Write-Warning "-- Project state was not saved. Please check the file path and try again."
                        }
                    }
                }
                
            }
            'Q' {
                Write-Host "Exiting..."
            }
            default {
                # Handle invalid options
                Write-Information "-- Invalid option. Please try again." -InformationAction Continue
                continue
            }
        }
    }
} while ($userOption -ne 'Q' -and $userOption -ne "10" ) # End the loop when the user chooses to quit
#endregion Menu

#region PM Project report
if (-not $NOPM) {
    # Example of summarizing all steps,  Log final response to file
    if (-not $NOLog) {
        $projectManagerResponse = $projectManager.ProcessInput($script:GlobalResponse -join ", ") | Out-File -FilePath (Join-Path $script:TeamDiscussionDataFolder "ProjectSummary.log")
    }
    else {
        $projectManagerResponse = $projectManager.ProcessInput($script:GlobalResponse -join ", ")
    }
    Add-ToGlobalResponses $projectManagerResponse
}
#endregion PM Project report

#region Final code
if (-not $NOLog) {
    # Log Developer last memory
    $TheFinalCodeFullName = Join-Path $script:TeamDiscussionDataFolder "TheCodeF.PS1"
    $lastPSDevCode | Out-File -FilePath $TheFinalCodeFullName
    #Export-AndWritePowerShellCodeBlocks -InputString $(get-content $(join-path $script:TeamDiscussionDataFolder "TheCodeF.log") -raw) -OutputFilePath $(join-path $script:TeamDiscussionDataFolder "TheCode.ps1") -StartDelimiter '```powershell' -EndDelimiter '```'
    if (Test-Path -Path $TheFinalCodeFullName) {
        # Call the function to check the code in 'TheCode.ps1' file
        Write-Information "The final code was exported to $TheFinalCodeFullName" -InformationAction Continue
        $issues = Invoke-CodeWithPSScriptAnalyzer -FilePath $TheFinalCodeFullName
        if ($issues) {
            write-output ($issues | Select-Object line, message | format-table -AutoSize -Wrap)
        }
    }
    foreach ($TeamMember in $Team) {
        $TeamMember.DisplayInfo(0) | Out-File -FilePath $TeamMember.LogFilePath -Append
    }
    Stop-Transcript
}
else {
    #Export-AndWritePowerShellCodeBlocks -InputString $($powerShellDeveloper.GetLastMemory().Response) -StartDelimiter '```powershell' -EndDelimiter '```' -OutputFilePath $(join-path ([System.Environment]::GetEnvironmentVariable("TEMP", "user")) "TheCodeF.ps1")
    # Call the function to check the code in 'TheCode.ps1' file
    $issues = Invoke-CodeWithPSScriptAnalyzer -ScriptBlock $lastPSDevCode
    if ($issues) {
        write-output ($issues | Select-Object line, message | format-table -AutoSize -Wrap)
    }
}
#endregion Final code
#endregion Main
