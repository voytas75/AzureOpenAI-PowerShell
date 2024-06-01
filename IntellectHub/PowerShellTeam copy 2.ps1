param(
    [string] $Topic = "Create CPU monitoring app",
    [bool] $Stream = $true
)

#region LanguageModelClass
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
        # Log the input
        $this.Log.Add("Processing input: $input")
        # Update status
        $this.Status = "In Progress"

        try {
            # Use the user-provided function to get the response
            $response = & $this.ResponseFunction -SystemPrompt $this.Prompt -UserPrompt $input -Temperature $this.Temperature -TopP $this.TopP
            # Log the response
            $this.Log.Add("Generated response: $response")
            # Store the response in memory with timestamp
            $this.ResponseMemory.Add([PSCustomObject]@{
                Response  = $response
                Timestamp = Get-Date
            })
            # Update status
            $this.Status = "Completed"
        } catch {
            # Log the error
            $this.Log.Add("Error: $_")
            # Update status
            $this.Status = "Error"
            throw $_
        }

        # Pass to the next expert if available
        if ($this.NextExpert -ne $null) {
            return $this.NextExpert.ProcessInput($response)
        } else {
            return $response
        }
    }

    [void] SetNextExpert([ProjectTeam] $nextExpert) {
        $this.NextExpert = $nextExpert
    }

    [void] AddLogEntry([string] $entry) {
        $this.Log.Add($entry)
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
        } else {
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
            $this.Log.Add("Generated summary: $summary")
            return $summary
        } catch {
            # Log the error
            $this.Log.Add("Error: $_")
            throw $_
        }
    }
}
#endregion LanguageModelClass

#region RolePromptsAndCreation
$SystemAnalystPrompt = @"
You are tasked with analyzing the feasibility and requirements of a PowerShell program. The goal is to clearly define the program's objectives, identify the necessary components, and outline the implementation strategy.

Background Information: PowerShell is a task automation and configuration management framework from Microsoft, consisting of a command-line shell and scripting language. It is widely used for managing and automating tasks across various Microsoft and non-Microsoft environments.

Instructions: 
- Evaluate the feasibility of creating the described PowerShell program.
- Define the program's objectives and key features.
- Identify the necessary components and tools within PowerShell to achieve this.
- Outline a high-level implementation strategy.
- Document any potential challenges or limitations.
"@

$SystemAnalyst = [ProjectTeam]::new(
    "John Doe",
    "Requirements Analyst",
    $SystemAnalystPrompt,
    0.6,
    0.9,
    [scriptblock]::Create({
        param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
        $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $topic -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4" -simpleresponse -OneTimeUserPrompt -Stream $true
        return $response
    })
)


$PowerShellDeveloperPrompt = @"
You are tasked with developing the PowerShell program based on the provided requirements and implementation strategy. Your goal is to write clean, efficient, and functional code that meets the specified objectives.

Background Information: PowerShell scripts can interact with a wide range of systems and applications, making it a versatile tool for system administrators and developers. Ensure your code adheres to best practices for readability, maintainability, and performance.

Instructions:
- Develop the PowerShell program according to the provided requirements and strategy.
- Ensure the code is modular and well-documented.
- Include error handling and logging where appropriate.
- Provide comments and explanations for complex sections of the code.
- Prepare a brief usage guide or documentation.
"@
$PowerShellDeveloper = [ProjectTeam]::new(
    "John Doe",
    "Requirements Analyst",
    $PowerShellDeveloperPrompt,
    0.6,
    0.9,
    [scriptblock]::Create({
        param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
        $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $topic -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4" -simpleresponse -OneTimeUserPrompt -Stream $true
        return $response
    })
)

$QualityAssurancePrompt = @"
You are tasked with testing and verifying the functionality of the developed PowerShell program. Your goal is to ensure the program works as intended, is free of bugs, and meets the specified requirements.

Background Information: PowerShell scripts can perform a wide range of tasks, so thorough testing is essential to ensure reliability and performance. Testing should cover all aspects of the program, including edge cases and potential failure points.

Instructions:
- Test the PowerShell program for functionality and performance.
- Verify that the program meets all specified requirements and objectives.
- Identify and document any bugs or issues.
- Suggest improvements or optimizations if necessary.
- Provide a final report on the program's quality and readiness for deployment.
"@
$QualityAssurance = [ProjectTeam]::new(
    "John Doe",
    "Requirements Analyst",
    $QualityAssurancePrompt,
    0.6,
    0.9,
    [scriptblock]::Create({
        param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
        $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $topic -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4" -simpleresponse -OneTimeUserPrompt -Stream $true
        return $response
    })
)
#endregion RolePromptsAndCreation

#region Importing Modules and Setting Up Discussion
# Import modules and scripts
[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "0", "User")
#Import-Module -Name PSaoAI
Import-module "D:\dane\voytas\Dokumenty\visual_studio_code\github\AzureOpenAI-PowerShell\PSAOAI\PSAOAI.psd1" -Force 
import-module PSWriteColor

#region Importing Helper Functions
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
#endregion Importing Helper Functions

#region Creating Team Discussion Folder
Try {
    # Get the current date and time
    $currentDateTime = Get-Date -Format "yyyyMMdd_HHmmss"
    # Create a folder with the current date and time as the name in the example path
    $script:TeamDiscussionDataFolder = Create-FolderInGivenPath -FolderPath $(Create-FolderInUserDocuments -FolderName "OpenDomainDiscussion") -FolderName $currentDateTime
    if ($script:TeamDiscussionDataFolder) {
        PSWriteColor\Write-Color -Text "Team discussion folder was created '$script:TeamDiscussionDataFolder'" -Color Blue -BackGroundColor Cyan -LinesBefore 0 -Encoding utf8 -ShowTime
    }
}
Catch {
    Write-Warning -Message "Failed to create discussion folder"
    return $false
}
#endregion Creating Team Discussion Folder
#endregion Importing Modules and Setting Up Discussion

<#
Write-Host $SystemAnalyst.name -BackgroundColor White -ForegroundColor Blue
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$SystemAnalystResponse = $SystemAnalyst.ChatCompletion($SystemAnalyst.ExpertPrompt, $Topic, $Stream)
$stopwatch.Stop()
$runtime = $stopwatch.Elapsed.TotalSeconds
Write-Host "Runtime: $runtime seconds" -BackgroundColor DarkGray -ForegroundColor White

Write-Host $PowerShellDeveloper.name -BackgroundColor White -ForegroundColor Blue
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$PowerShellDeveloperResponse = $PowerShellDeveloper.ChatCompletion($PowerShellDeveloper.ExpertPrompt, $SystemAnalystResponse, $Stream)
$stopwatch.Stop()
$runtime = $stopwatch.Elapsed.TotalSeconds
Write-Host "Runtime: $runtime seconds" -BackgroundColor DarkGray -ForegroundColor White

Write-Host $QualityAssurance.name -BackgroundColor White -ForegroundColor Blue
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$QualityAssuranceResponse = $QualityAssurance.ChatCompletion($QualityAssurance.ExpertPrompt, $PowerShellDeveloperResponse, $Stream)
$stopwatch.Stop()
$runtime = $stopwatch.Elapsed.TotalSeconds
Write-Host "Runtime: $runtime seconds" -BackgroundColor DarkGray -ForegroundColor White
#>


# Simulate adding responses to memory
$SystemAnalyst.ProcessInput($Topic)

# Display the info
$SystemAnalyst.DisplayInfo()

# Get the summary of the memory
$summary = $SystemAnalyst.SummarizeMemory()
Write-Host "Summary: $summary"
