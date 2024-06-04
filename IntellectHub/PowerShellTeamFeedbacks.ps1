<#
.SYNOPSIS
This script simulates a team of experts working on a PowerShell project.

.DESCRIPTION
The script creates a team of experts, each with a specific role in the project. Each expert processes the input, performs their role, and passes the result to the next expert. The process continues until all experts have completed their tasks.

.PARAMETER userInput
A string that describes the project. The default value is "A PowerShell project to monitor RAM load and display a single color block based on the load."

.PARAMETER Stream
A boolean value that indicates whether to stream the output. The default value is $true.

.EXAMPLE
.\PowerShellTeam.ps1 -userInput "A PowerShell project to monitor CPU load and display a graph based on the load." -Stream $false

.LINK
https://chatgpt.com/share/92f8cea1-88a6-497e-b894-6146e3c2a81c
#>
param(
    [string] $userInput = "A PowerShell project to monitor RAM load and display a single color block based on the load.",
    [bool] $Stream = $true
)

#region LanguageModelClass
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
    [array] $TeamMembers
    
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
        $this.TeamMembers = @()
    }

    [void] DisplayInfo() {
        Write-Host "Name: $($this.Name)"
        Write-Host "Role: $($this.Role)"
        Write-Host "Prompt: $($this.Prompt)"
        Write-Host "Temperature: $($this.Temperature)"
        Write-Host "TopP: $($this.TopP)"
        Write-Host "Status: $($this.Status)"
        Write-Host "Log: $($this.Log -join ', ')"
        Write-Host "Responses:"
        foreach ($memory in $this.ResponseMemory) {
            Write-Host "[$($memory.Timestamp)] $($memory.Response)"
        }
    }

    [string] ProcessInput([string] $input) {
        Write-Host "---------------------------------------------------------------------------------"
        Write-Host "Current Expert: $($this.Name) - $($this.Role)"
        Write-Host "---------------------------------------------------------------------------------"
        # Log the input
        $this.AddLogEntry("Processing input: $input")
        # Update status
        $this.Status = "In Progress"
        #write-Host $script:Stream
        try {
            # Use the user-provided function to get the response
            $response = & $this.ResponseFunction -SystemPrompt $this.Prompt -UserPrompt $input -Temperature $this.Temperature -TopP $this.TopP
            if (-not $script:Stream) {
                #write-host ($response | convertto-json -Depth 100)
                Write-Host $response
            }
            # Log the response
            $this.AddLogEntry("Generated response: $response")
            # Store the response in memory with timestamp
            $this.ResponseMemory.Add([PSCustomObject]@{
                    Response  = $response
                    Timestamp = Get-Date
                })
            $feedbackSummary = ""
            if ($this.TeamMembers.count -gt 0) {
                # Request feedback for the response
                $feedbackSummary = $this.RequestFeedback($response)
                # Log the feedback summary
                $this.AddLogEntry("Feedback summary: $feedbackSummary")
            }
            # Integrate feedback into response
            $responseWithFeedback = "$response`n`n$feedbackSummary"

            # Update status
            $this.Status = "Completed"
        }
        catch {
            # Log the error
            $this.AddLogEntry("Error: $_")
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

    [void] SetNextExpert([ProjectTeam] $nextExpert) {
        $this.NextExpert = $nextExpert
    }

    [ProjectTeam] GetNextExpert() {
        return $this.NextExpert
    }

    [void] AddLogEntry([string] $entry) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] $entry"
        $this.Log.Add($logEntry)
        # Write the log entry to the file
        Add-Content -Path $this.LogFilePath -Value $logEntry
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

    [string] ProcessBySpecificExpert([ProjectTeam] $expert, [string] $input) {
        return $expert.ProcessInput($input)
    }

    [System.Collections.ArrayList] RequestFeedback([string] $response) {
        $feedbacks = @()

        foreach ($member in $this.TeamMembers) {
            Write-Host "---------------------------------------------------------------------------------"
            Write-Host "Feedback from $($member.Role) to $($this.Role)"
            Write-Host "---------------------------------------------------------------------------------"
    
            # Send feedback request and collect feedback
            $feedback = SendFeedbackRequest -TeamMember $member.Role -Response $response -Prompt $this.Prompt -Temperature $this.Temperature -TopP $this.TopP -ResponseFunction $this.ResponseFunction
        
            if ($null -ne $feedback) {
                $feedbacks += $feedback
            }
        }

        if ($feedbacks.Count -eq 0) {
            throw "No feedback received from team members."
        }

        return $feedbacks
    }

    [void] AddTeamMember([ProjectTeam] $member) {
        $this.TeamMembers.Add($member)
    }

    [void] RemoveTeamMember([ProjectTeam] $member) {
        $this.TeamMembers.Remove($member)
    }
}
#endregion LanguageModelClass

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
    $Systemprompt = @"
You act as $TeamMember, your task is to review the following response and provide your feedback.

"@

    # Send the feedback request to the LLM model
    $feedback = & $ResponseFunction -SystemPrompt $SystemPrompt -UserPrompt $Response -Temperature $Temperature -TopP $TopP

    # Return the feedback
    return $feedback
}


function GetLastMemoryFromTeamMembers {
    param (
        [array] $TeamMembers
    )

    $lastMemories = @()

    foreach ($member in $TeamMembers) {
        $lastMemory = $member.GetLastMemory().Response
        $lastMemories += $lastMemory
    }

    return ($lastMemories -join "`n")
}


#region Importing Modules and Setting Up Discussion
# Disabe PSAOAI importing banner
[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "0", "User")
#Import-Module -Name PSaoAI
Import-module "D:\dane\voytas\Dokumenty\visual_studio_code\github\AzureOpenAI-PowerShell\PSAOAI\PSAOAI.psd1" -Force 

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
    # Create a folder with the current date and time as the name in the example path
    $script:TeamDiscussionDataFolder = Create-FolderInGivenPath -FolderPath $(Create-FolderInUserDocuments -FolderName "OpenDomainDiscussion") -FolderName $currentDateTime
    if ($script:TeamDiscussionDataFolder) {
        Write-Host "Team discussion folder was created '$script:TeamDiscussionDataFolder'" -ForegroundColor Blue -BackGroundColor Cyan 
    }
}
Catch {
    Write-Warning -Message "Failed to create discussion folder"
    return $false
}
#endregion


# Create ProjectTeam expert objects
$HelperExpert = [ProjectTeam]::new(
    "Helper Expert",
    "Helper Expert",
    "",
    0.2,
    0.8,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4turbo" -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)

$requirementsAnalyst = [ProjectTeam]::new(
    "Requirements Analyst",
    "Requirements Analyst",
    @"
You act as Requirements Analyst. Let's think step-by-step. You are tasked with analyzing the feasibility and requirements of a PowerShell program. The goal is to clearly define the program's objectives, identify the necessary components, and outline the implementation strategy.
Background Information: PowerShell is a task automation and configuration management framework from Microsoft, consisting of a command-line shell and scripting language. It is widely used for managing and automating tasks across various Microsoft and non-Microsoft environments.
Instructions:
- Evaluate the feasibility of creating the described PowerShell program, including technical, operational, and financial aspects.
- Define the program's objectives and key features in detail.
- Identify the necessary components and tools within PowerShell to achieve this.
- Outline a high-level implementation strategy.
- Document any potential challenges or limitations.
- Provide a detailed feasibility report covering all aspects mentioned.
"@,
    0.6,
    0.9,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4p" -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)
<#
feedback instruction for powershell dev data:
"You act as Requirements Analyst. Let's think step-by-step. You are tasked with analyzing the feasibility and requirements of a PowerShell program. The goal is to clearly define the program's objectives, identify the necessary components, and outline the implementation strategy.
Background Information: PowerShell is a task automation and configuration management framework from Microsoft, consisting of a command-line shell and scripting language. It is widely used for managing and automating tasks across various Microsoft and non-Microsoft environments.
Instructions:
1. Evaluate the feasibility of creating the described PowerShell program, including technical, operational, and financial aspects:
   - Assess the technical feasibility by considering the compatibility of the proposed solution with existing systems and infrastructure.
   - Evaluate operational feasibility by analyzing the impact of the program on day-to-day operations and workflows.
   - Consider the financial feasibility by estimating the costs associated with development, deployment, and maintenance.
2. Define the program's objectives and key features in detail:
   - Clearly articulate the primary objectives and secondary goals of the PowerShell program, ensuring alignment with business needs.
   - Specify key features and functionalities required to achieve the program's objectives effectively.
3. Identify the necessary components and tools within PowerShell to achieve this:
   - Identify and list the core components, modules, and cmdlets required to implement the desired features and functionalities.
   - Evaluate the availability and compatibility of third-party tools or libraries that may enhance the program's capabilities.
4. Outline a high-level implementation strategy:
   - Develop a high-level plan that outlines the sequence of tasks, milestones, and deliverables for the PowerShell program development.
   - Define roles and responsibilities for team members involved in the implementation process.
5. Document any potential challenges or limitations:
   - Identify and document potential technical, operational, or resource-related challenges that may hinder the successful implementation of the PowerShell program.
   - Propose mitigation strategies or alternative solutions to address these challenges effectively.
6. Provide a detailed feasibility report covering all aspects mentioned:
   - Compile all findings and analyses into a comprehensive feasibility report, including detailed assessments of technical, operational, and financial feasibility.
   - Include recommendations and actionable insights to guide decision-making and project planning.
7. Review PowerShell Developer's code and provide feedback:
   - Thoroughly review the PowerShell code produced by the developer against the defined objectives and requirements.
   - Evaluate the code for adherence to best practices, readability, efficiency, and maintainability.
   - Provide constructive feedback on areas for improvement, including suggestions for code optimization, refactoring, and documentation.
   - Collaborate with the developer to address any identified issues and ensure the code meets the project's quality standards.
"
#>


$domainExpert = [ProjectTeam]::new(
    "Domain Expert",
    "Domain Expert",
    @"
You act as Domain Expert. Let's think step-by-step. Provide specialized insights and recommendations based on the specific domain requirements of the project. This includes:
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
"@,
    0.65,
    0.9,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4turbo" -simpleresponse -OneTimeUserPrompt -Stream $script:Stream
            return $response
        })
)



$systemArchitect = [ProjectTeam]::new(
    "System Architect",
    "System Architect",
    @"
You act as System Architect. Let's think step-by-step. Design the architecture for a PowerShell project. This includes:
- Outlining the overall structure of the program.
- Identifying and defining necessary modules and functions.
- Creating detailed architectural design documents and visual diagrams (e.g., flowcharts, UML diagrams).
- Ensuring the architecture supports scalability, maintainability, and performance.
- Defining data flow and interaction between different components.
- Selecting appropriate technologies and tools for the project.
- Providing guidelines for coding standards and best practices.
- Documenting security considerations and ensuring the architecture adheres to best security practices.
- Creating a detailed architectural design document.
"@,
    0.7,
    0.85,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4p" -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)

$powerShellDeveloper = [ProjectTeam]::new(
    "PowerShell Developer",
    "PowerShell Developer",
    @"
You act as PowerShell Developer. Let's think step-by-step. You are tasked with developing the PowerShell program based on the provided requirements and implementation strategy. Your goal is to write clean, efficient, and functional code that meets the specified objectives.
Background Information: PowerShell scripts can interact with a wide range of systems and applications, making it a versatile tool for system administrators and developers. Ensure your code adheres to PowerShell best practices for readability, maintainability, and performance.
Instructions:
1. Develop the PowerShell program according to the provided requirements and strategy:
    - Review the requirements and implementation strategy thoroughly before starting development.
    - Break down the tasks into manageable chunks and implement them iteratively.
2. Ensure the code is modular and well-documented with help blocks:
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
"@,
    0.65,
    0.8,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4turbo" -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)

$qaEngineer = [ProjectTeam]::new(
    "QA Engineer",
    "QA Engineer",
    @"
You act as QA Engineer. Let's think step-by-step. You are tasked with testing and verifying the functionality of the developed PowerShell program. Your goal is to ensure the program works as intended, is free of bugs, and meets the specified requirements.
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
"@,
    0.6,
    0.9,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4p" -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)

$documentationSpecialist = [ProjectTeam]::new(
    "Documentation Specialist",
    "Documentation Specialist",
    @"
You act as Documentation Specialist. Let's think step-by-step. Create comprehensive documentation for the PowerShell project. This includes:
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
"@,
    0.6,
    0.8,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4p" -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)

$projectManager = [ProjectTeam]::new(
    "Project Manager",
    "Project Manager",
    @"
You act as Project Manager. Let's think step-by-step. Provide a comprehensive summary of the PowerShell project based on the completed tasks of each expert. This includes:
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
"@,
    0.7,
    0.85,
    [scriptblock]::Create({
            param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
            $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4p" -simpleresponse -OneTimeUserPrompt -Stream $script:Stream -LogFolder $script:TeamDiscussionDataFolder
            return $response
        })
)

Start-Transcript -Path (join-path $script:TeamDiscussionDataFolder "transcript.log")

$GlobalResponse = @()
$TeamMembers = @()
$TeamMembers += $requirementsAnalyst
$TeamMembers += $systemArchitect
$TeamMembers += $domainExpert
$powerShellDeveloper.TeamMembers = $TeamMembers

$HelperExpert.Prompt = "Based on user input create project description and objective."
$HelperExpertResponse = $HelperExpert.ProcessInput($userInput)

$userInputoryginal = $userInput
$userInput = @"
User input: $userinput
$HelperExpertResponse
"@

# Example of starting the process
$requirementsAnalystresponse = $requirementsAnalyst.ProcessInput($userInput)
$GlobalResponse += $requirementsAnalystresponse
$systemArchitectResponse = $systemArchitect.ProcessInput($GlobalResponse -join ", ")
$GlobalResponse += $systemArchitectResponse
$domainExpertResponse = $domainExpert.ProcessInput($GlobalResponse -join ", ")
$GlobalResponse += $domainExpertResponse
$powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput($GlobalResponse -join ", ")
$GlobalResponse += $powerShellDeveloperResponce
$PSDevTeamMembersMemory = GetLastMemoryFromTeamMembers -TeamMembers $TeamMembers
$powerShellDeveloper.TeamMembers = $null
$powerShellDeveloperResponce = $powerShellDeveloper.ProcessInput($PSDevTeamMembersMemory)
$qaEngineerResponse = $qaEngineer.ProcessInput($powerShellDeveloperResponce)
$GlobalResponse += $qaEngineerResponse

# Example of re-routing: QA Engineer's response goes to PowerShell Developer and then Documentation Specialist
$devandqamemory = $(($powerShellDeveloper.GetLastMemory().Response, $qaEngineer.GetLastMemory().Response) -join "`n") + "Improve and optimize the code based on the QA Engineer's feedback"

$powerShellDeveloperresponse = $powerShellDeveloper.ProcessInput($devandqamemory)
$GlobalResponse += $powerShellDeveloperresponse

$documentationSpecialistResponce = $documentationSpecialist.ProcessInput($powerShellDeveloperresponse)
$GlobalResponse += $documentationSpecialistResponce

# Log final response to file
$documentationSpecialistResponce | Out-File -FilePath (Join-Path $script:TeamDiscussionDataFolder "Documentation.log")

# Example of summarizing all steps,  Log final response to file
$projectManager.ProcessInput($GlobalResponse -join ", ") | Out-File -FilePath (Join-Path $script:TeamDiscussionDataFolder "ProjectSummary.log")

# Log Developer last memory
($powerShellDeveloper.GetLastMemory().Response) | Out-File -FilePath (Join-Path $script:TeamDiscussionDataFolder "TheCode.log")
.\Extract-AndWrite-PowerShellCodeBlocks.ps1 -InputString $(get-content $(join-path $script:TeamDiscussionDataFolder "TheCode.log") -raw) -OutputFilePath $(join-path $script:TeamDiscussionDataFolder "TheCode.ps1")
Stop-Transcript
