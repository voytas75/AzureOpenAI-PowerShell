<# 
.SYNOPSIS 
Emulates a team of specialists working collaboratively on a PowerShell project.

.DESCRIPTION 
This script simulates forming a team of specialists where each member has a unique role in executing a project. The input is processed by one specialist who then executes their designated task and passes the result onto the next specialist. This chain continues until all tasks are completed.

.PARAMETER userInput 
Specifies the outline of the project as a string. The default value describes monitoring RAM load and displaying color based on load levels.

.PARAMETER Stream 
Determines whether output should be streamed live. By setting this parameter to $true (default), output will be streamed. If set to $false, streaming will be disabled.

.PARAMETER NOPM 
An optional switch that disables Project Manager functions when present.

.PARAMETER NODocumentator 
An optional switch that disables Documentator functions when present.

.INPUTS 
None. You cannot pipe objects to this script directly but must pass them as arguments using parameters defined above.

.OUTPUTS 
Output varies depending on how each specialist processes their part of the project; typically text-based results are expected which may include status messages or visual representations like graphs or color blocks related to system metrics such as RAM load etc., depending upon user input specification provided via 'userInput' parameter

.EXAMPLE 
PS> .\PowerShellTeamFeedbacks.ps1 -userInput "A PowerShell project to monitor CPU usage and display dynamic graph." -Stream $false

This command runs the script without streaming output live (-Stream $false) while specifying custom user input about monitoring CPU usage instead of RAM and displaying it through dynamic graphing methods rather than static color blocks.

.NOTES 
Version: 1.0.0
Author: voytas75
Creation Date: 06.2024
Purpose/Change: Initial release for emulating teamwork within PowerShell scripting context
#>
param(
    [string] $userInput = "A PowerShell project to monitor RAM load and display a single color block based on the load.",
    [bool] $Stream = $false,
    [switch] $NOPM,
    [switch] $NODocumentator,
    [switch] $NOLog,
    [string] $LogFolder,
    [ValidateSet("Mistral", "Phi3", "gemma", "codegemma", "llama3", "phi3:medium")] 
    [string] $model = "Phi3:medium"

)

#region ProjectTeamClass
<#
.SYNOPSIS
The ProjectTeam class represents an expert in the team.

.DESCRIPTION
Each expert has a name, role, prompt, and a function to process the input. The expert can also log their actions, store their responses, and pass the input to the next expert.

.METHODS
DisplayInfo: Displays the expert's information.
DisplayHeader: Displays the expert's name and role.
ProcessInput: Processes the input and returns the response.
SetNextExpert: Sets the next expert in the workflow.
GetNextExpert: Returns the next expert in the workflow.
AddLogEntry: Adds an entry to the log.
Notify: Sends a notification (currently just displays a message).
GetMemory: Returns the expert's memory (responses).
GetLastMemory: Returns the last response from the expert's memory.
SummarizeMemory: Summarizes the expert's memory.
ProcessBySpecificExpert: Processes the input by a specific expert.
#>
class ProjectTeam {
    [string] $Name
    [string] $Role
    [string] $Prompt
    [ProjectTeam] $NextExpert
    [System.Collections.ArrayList] $ResponseMemory
    [double] $Temperature
    [double] $TopP
    [string] $Status
    [System.Collections.ArrayList] $Log
    [scriptblock] $ResponseFunction
    [string] $LogFilePath
    [array] $FeedbackTeam
    
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

    [PSCustomObject] DisplayInfo([int] $display = 1) {
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
        
        $infoObject = New-Object -TypeName PSCustomObject -Property $info

        if ($display -eq 1) {
            Write-Host "---------------------------------------------------------------------------------"
            Write-Host "Info: $($this.Name) ($($this.Role))"
            Write-Host "---------------------------------------------------------------------------------"
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

        return $infoObject
    }
    
    [string] ProcessInput([string] $userinput) {
        Write-Host "---------------------------------------------------------------------------------"
        Write-Host "Current Expert: $($this.Name) ($($this.Role))"
        Write-Host "---------------------------------------------------------------------------------"
        # Log the input
        $this.AddLogEntry("Processing input:`n$userinput")
        # Update status
        $this.Status = "In Progress"
        #write-Host $script:Stream
        try {
            # Use the user-provided function to get the response
            $response = & $this.ResponseFunction -SystemPrompt $this.Prompt -UserPrompt $userinput
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

    [string] Feedback([string] $input) {
        Write-Host "---------------------------------------------------------------------------------"
        Write-Host "Feedback by $($this.Name) ($($this.Role))"
        Write-Host "---------------------------------------------------------------------------------"
        # Log the input
        $this.AddLogEntry("Processing input:`n$input")
        # Update status
        $this.Status = "In Progress"
        try {
            # Use the user-provided function to get the response
            $response = & $this.ResponseFunction -SystemPrompt $this.Prompt -UserPrompt $Input
            if (-not $script:Stream) {
                Write-Host $response
            }
            # Log the response
            $this.AddLogEntry("Generated feedback response:`n$response")
            # Store the response in memory with timestamp
            $this.ResponseMemory.Add([PSCustomObject]@{
                    Response  = $response
                    Timestamp = Get-Date
                })
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
        $logEntry = @"
[$timestamp]:
---------------------------------------------------------------------------------
$entry
---------------------------------------------------------------------------------
"@
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
            $this.AddLogEntry("Generated summary: $summary")
            return $summary
        }
        catch {
            # Log the error
            $this.AddLogEntry("Error: $_")
            throw $_
        }
    }

    [string] ProcessBySpecificExpert([ProjectTeam] $expert, [string] $userinput) {
        return $expert.ProcessInput($userinput)
    }

    [System.Collections.ArrayList] RequestFeedback([string] $response) {
        $feedbacks = @()

        foreach ($FeedbackMember in $this.FeedbackTeam) {
            Write-Host "---------------------------------------------------------------------------------"
            Write-Host "Feedback from $($FeedbackMember.Role) to $($this.Role)"
            Write-Host "---------------------------------------------------------------------------------"
    
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
        [string] $TeamMember,
        [string] $Response,
        [string] $Prompt,
        [double] $Temperature,
        [double] $TopP,
        [scriptblock] $ResponseFunction
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


function GetLastMemoryFromFeedbackTeamMembers {
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

function AddToGlobalResponses {
    param($response)
    $script:GlobalResponse += $response
}
#endregion Functions

#region Importing Modules and Setting Up Discussion
# Disabe PSAOAI importing banner
[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "0", "User")

if (Get-Module -ListAvailable -Name PSAOAI) {
    [void](Import-module -name PSAOAI -Force)
}
else {
    Write-Host "You need to install PSAOAI module. Use: 'Install-Module PSAOAI'"
    return
}
  
#region Importing Helper Functions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$helperFunctionsPath = Join-Path -Path $scriptPath -ChildPath "helper_functions.ps1"
Try {
    . $helperFunctionsPath
    Write-Host "Imported helper function file" -ForegroundColor Blue -BackGroundColor Cyan
}
Catch {
    Write-Error -Message "Failed to import helper function file"
    return $false
}
#endregion Importing Helper Functions

#region Creating Team Discussion Folder
Try {
    # Get the current date and time
    $currentDateTime = Get-Date -Format "yyyyMMdd_HHmmss"
    if ($LogFolder) {
        # Create a folder with the current date and time as the name in the example path
        $script:TeamDiscussionDataFolder = Create-FolderInGivenPath -FolderPath $LogFolder -FolderName $currentDateTime
    }
    else {
        # Create a folder with the current date and time as the name in the example path
        $script:TeamDiscussionDataFolder = Create-FolderInGivenPath -FolderPath $(Create-FolderInUserDocuments -FolderName "OpenDomainDiscussion") -FolderName $currentDateTime
    }
    if ($script:TeamDiscussionDataFolder) {
        Write-Host "Team discussion folder was created '$script:TeamDiscussionDataFolder'" -ForegroundColor Blue -BackGroundColor Cyan 
    }
}
Catch {
    Write-Warning -Message "Failed to create discussion folder"
    return $false
}
#endregion Creating Team Discussion Folder

#region ProjectTeam
# Create ProjectTeam expert objects
$HelperExpertRole = "Helper Expert"
$HelperExpert = [ProjectTeam]::new(
    "Helper",
    $HelperExpertRole,
    "You are helpful and valuable Assistant named {0}." -f $HelperExpertRole,
    0.4,
    0.8,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $model)
            $response = .\ollama.ps1 -SystemMessage $SystemPrompt -UserMessage $UserPrompt -model $model
            return $response
        })
)

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
            param ($SystemPrompt, $UserPrompt, $model)
            $response = .\ollama.ps1 -SystemMessage $SystemPrompt -UserMessage $UserPrompt -model -$model
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
            param ($SystemPrompt, $UserPrompt, $model)
            $response = .\ollama.ps1 -SystemMessage $SystemPrompt -UserMessage $UserPrompt -model -$model
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
            param ($SystemPrompt, $UserPrompt, $model)
            $response = .\ollama.ps1 -SystemMessage $SystemPrompt -UserMessage $UserPrompt -model -$model
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
    - Use knowledge from the help topic 'about_Comment_Based_Help'. You must add '.NOTES' with additional information 'Version' and 'Updates'. '.NOTES' contains all updates and versions for clarity of documentation. 
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
            param ($SystemPrompt, $UserPrompt, $model)
            $response = .\ollama.ps1 -SystemMessage $SystemPrompt -UserMessage $UserPrompt -model -$model
            return $response
        })
)

$qaEngineerRole = "Quality Assurance Engineer"
$qaEngineer = [ProjectTeam]::new(
    "QA Engineer",
    $qaEngineerRole,
    @"
You act as {0}. You are tasked with testing and verifying the functionality of the developed PowerShell program. Your goal is to ensure the program works as intended, is free of bugs, and meets the specified requirements.
Background Information: PowerShell scripts can perform a wide range of tasks, so thorough testing is essential to ensure reliability and performance. Testing should cover all aspects of the program, including edge cases and potential failure points.
Instructions:
- Test the PowerShell program for functionality and performance.
- Verify that the program meets all specified requirements and objectives.
- Identify and document any bugs or issues.
- Suggest improvements or optimizations if necessary.
- Provide a final report on the program's quality and readiness for deployment.
- Recommend specific testing frameworks and tools.
- Integrate tests into a CI/CD pipeline.
- Include performance and load testing as part of the QA process.
- Generate a list of verification questions that could help to self-analyze.
Think step by step. Make sure your answer is unbiased.
"@ -f $qaEngineerRole,
    0.6,
    0.9,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $model)
            $response = .\ollama.ps1 -SystemMessage $SystemPrompt -UserMessage $UserPrompt -model -$model
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
            param ($SystemPrompt, $UserPrompt, $model)
            $response = .\ollama.ps1 -SystemMessage $SystemPrompt -UserMessage $UserPrompt -model -$model
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
            param ($SystemPrompt, $UserPrompt, $model)
            $response = .\ollama.ps1 -SystemMessage $SystemPrompt -UserMessage $UserPrompt -model -$model
            return $response
        })
)
#endregion ProjectTeam

#region Main
$GlobalResponse = @()
$GlobalPSDevResponse = @()

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

$userInputOryginal = $userInput
$projectManagerFeedback = $projectManager.Feedback("Based on user input create detailed and concise project name, description, objectives, deliverables, additional considerations, and success criteria. I will tip you `$100 for including all the elements provided by the user.`n`n````````text`n" + $userInputOryginal + "`n`````````n")
AddToGlobalResponses $projectManagerFeedback
$script:userInput = $projectManagerFeedback

$powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput("Based on $($projectManager.Name) review, create the version 1.0 of the code.`n`n````````text`n" + $($projectManager.GetLastMemory().Response) + "`n`````````n`nThink step by step. Make sure your answer is unbiased. I will tip you `$50 for the code.")
$GlobalPSDevResponse += $powerShellDeveloperResponce
AddToGlobalResponses $powerShellDeveloperResponce

$FeedbackPrompt = @"
Review the following response and provide your suggestions for improvement as feedback to Powershell Developer. Generate a list of verification questions that could help to self-analyze. 
I will tip you `$100 when your suggestions are consistent with the project description and objectives. 

$($script:userInput.trim())

````````text
$($powerShellDeveloperResponce.trim())
````````

Think step by step. Make sure your answer is unbiased.
"@
$requirementsAnalystFeedback = $requirementsAnalyst.Feedback($FeedbackPrompt)
AddToGlobalResponses $requirementsAnalystFeedback

$powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput("Based on $($requirementsAnalyst.Name) feedback, modify the code with suggested improvements and optimizations. The previous version of the code has been shared below after the feedback block.`n`n" + $($requirementsAnalyst.GetLastMemory().Response) + "`n`nHere is version 1.0 of the code:`n`n````````text`n" + $($powerShellDeveloper.GetLastMemory().response) + "`n`````````n`nThink step by step. Make sure your answer is unbiased. I will tip you `$100 for the correct code.")
$GlobalPSDevResponse += $powerShellDeveloperResponce
AddToGlobalResponses $powerShellDeveloperResponce

$FeedbackPrompt = @"
Review the following response and provide your suggestions for improvement as feedback to Powershell Developer. Generate a list of verification questions that could help to self-analyze. 
I will tip you `$100 when your suggestions are consistent with the project description and objectives. 

$($script:userInput.trim())

````````text
$($powerShellDeveloperResponce.trim())
````````

Think step by step. Make sure your answer is unbiased.
"@
$systemArchitectFeedback = $systemArchitect.Feedback($FeedbackPrompt)
AddToGlobalResponses $systemArchitectFeedback

$powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput("Based on $($systemArchitect.Name) feedback, modify the code with suggested improvements and optimizations. The previous version of the code has been shared below after the feedback block.`n`n" + $($systemArchitect.GetLastMemory().Response) + "`n`nHere is version 1.0 of the code:`n`n````````text`n" + $($powerShellDeveloper.GetLastMemory().response) + "`n`````````n`nThink step by step. Make sure your answer is unbiased. I will tip you `$150 for the correct code.")
$GlobalPSDevResponse += $powerShellDeveloperResponce
AddToGlobalResponses $powerShellDeveloperResponce

$FeedbackPrompt = @"
Review the following response and provide your suggestions for improvement as feedback to Powershell Developer. Generate a list of verification questions that could help to self-analyze. 
I will tip you `$100 when your suggestions are consistent with the project description and objectives. 

$($script:userInput.trim())

````````text
$($powerShellDeveloperResponce.trim())
````````

Think step by step. Make sure your answer is unbiased.
"@
$domainExpertFeedback = $domainExpert.Feedback($FeedbackPrompt)
AddToGlobalResponses $domainExpertFeedback

$powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput("Based on $($domainExpert.Name) feedback, modify the code with suggested improvements and optimizations. The previous version of the code has been shared below after the feedback block.`n`n" + $($domainExpert.GetLastMemory().Response) + "`n`nHere is version 1.0 of the code:`n`n````````text`n" + $($powerShellDeveloper.GetLastMemory().response) + "`n`````````n`nThink step by step. Make sure your answer is unbiased. I will tip you `$200 for the correct code.")
$GlobalPSDevResponse += $powerShellDeveloperResponce
AddToGlobalResponses $powerShellDeveloperResponce

$FeedbackPrompt = @"
Review the following response and provide your suggestions for improvement as feedback to Powershell Developer. Generate a list of verification questions that could help to self-analyze. 
I will tip you `$100 when your suggestions are consistent with the project description and objectives. 

$($script:userInput.trim())

````````text
$($powerShellDeveloperResponce.trim())
````````

Think step by step. Make sure your answer is unbiased.
"@
$qaEngineerFeedback = $qaEngineer.Feedback($FeedbackPrompt)
AddToGlobalResponses $qaEngineerFeedback

$powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput("Based on $($qaEngineer.Name) feedback, modify the code with suggested improvements and optimizations. The previous version of the code has been shared below after the feedback block.`n`n" + $($qaEngineer.GetLastMemory().Response) + "`n`nHere is version 1.0 of the code:`n`n````````text`n" + $($powerShellDeveloper.GetLastMemory().response) + "`n`````````n`nThink step by step. Make sure your answer is unbiased. I will tip you `$300 for the correct code.")
$GlobalPSDevResponse += $powerShellDeveloperResponce
AddToGlobalResponses $powerShellDeveloperResponce

if (-not $NODocumentator) {
    if (-not $NOLog) {
        $documentationSpecialistResponce = $documentationSpecialist.ProcessInput($powerShellDeveloperresponse) | Out-File -FilePath (Join-Path $script:TeamDiscussionDataFolder "Documentation.log")
    }
    else {
        $documentationSpecialistResponce = $documentationSpecialist.ProcessInput($powerShellDeveloperresponse)
    }
    AddToGlobalResponses $documentationSpecialistResponce
}

if (-not $NOPM) {
    # Example of summarizing all steps,  Log final response to file
    if (-not $NOLog) {
        $projectManagerResponse = $projectManager.ProcessInput($script:GlobalResponse -join ", ") | Out-File -FilePath (Join-Path $script:TeamDiscussionDataFolder "ProjectSummary.log")
    }
    else {
        $projectManagerResponse = $projectManager.ProcessInput($script:GlobalResponse -join ", ")
    }
    AddToGlobalResponses $projectManagerResponse
}

if (-not $NOLog) {
    # Log Developer last memory
    ($powerShellDeveloper.GetLastMemory().Response) | Out-File -FilePath (Join-Path $script:TeamDiscussionDataFolder "TheCode.log")
    .\Extract-AndWrite-PowerShellCodeBlocks.ps1 -InputString $(get-content $(join-path $script:TeamDiscussionDataFolder "TheCode.log") -raw) -OutputFilePath $(join-path $script:TeamDiscussionDataFolder "TheCode.ps1")

    foreach ($TeamMember in $Team) {
        $TeamMember.DisplayInfo(0) | Out-File -FilePath $TeamMember.LogFilePath -Append
    }
    Stop-Transcript
}
#endregion Main
