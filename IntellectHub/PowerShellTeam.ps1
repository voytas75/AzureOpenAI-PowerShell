param(
    [string] $userInput = "A PowerShell project to monitor RAM load and display a single color block based on the load.",
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
    [string] $LogFilePath

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

    [void] DisplayHeader() {
        Write-Host "----------------------------------------"
        Write-Host "Current Expert: $($this.Name) - $($this.Role)"
        Write-Host "----------------------------------------"
    }

    [string] ProcessInput([string] $input) {
        $this.DisplayHeader()
        # Log the input
        $this.AddLogEntry("Processing input: $input")
        # Update status
        $this.Status = "In Progress"

        try {
            # Use the user-provided function to get the response
            $response = & $this.ResponseFunction -SystemPrompt $this.Prompt -UserPrompt $input -Temperature $this.Temperature -TopP $this.TopP
            # Log the response
            $this.AddLogEntry("Generated response: $response")
            # Store the response in memory with timestamp
            $this.ResponseMemory.Add([PSCustomObject]@{
                Response  = $response
                Timestamp = Get-Date
            })
            # Update status
            $this.Status = "Completed"
        } catch {
            # Log the error
            $this.AddLogEntry("Error: $_")
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
            $this.AddLogEntry("Generated summary: $summary")
            return $summary
        } catch {
            # Log the error
            $this.AddLogEntry("Error: $_")
            throw $_
        }
    }
}
#endregion LanguageModelClass

#region Importing Modules and Setting Up Discussion
# Import modules and scripts
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
$requirementsAnalyst = [ProjectTeam]::new(
    "Requirements Analyst",
    "Requirements Analyst",
    "Analyze the requirements for a PowerShell project. Document the detailed specifications, define the scope, and create use case scenarios based on the user's input.",
    0.6,
    0.9,
    [scriptblock]::Create({
        param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
        $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4" -simpleresponse -OneTimeUserPrompt -Stream $true -LogFolder $script:TeamDiscussionDataFolder
        return $response
    })
)

$systemArchitect = [ProjectTeam]::new(
    "System Architect",
    "System Architect",
    "Design the architecture for a PowerShell project. Outline the program's structure, identify necessary modules and functions, and provide a detailed architectural design document.",
    0.7,
    0.85,
    [scriptblock]::Create({
        param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
        $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4" -simpleresponse -OneTimeUserPrompt -Stream $true -LogFolder $script:TeamDiscussionDataFolder
        return $response
    })
)

$powerShellDeveloper = [ProjectTeam]::new(
    "PowerShell Developer",
    "PowerShell Developer",
    "Develop a PowerShell script based on the design. Implement features, ensure code follows best practices, and provide initial unit tests.",
    0.65,
    0.8,
    [scriptblock]::Create({
        param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
        $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4turbo" -simpleresponse -OneTimeUserPrompt -Stream $true -LogFolder $script:TeamDiscussionDataFolder
        return $response
    })
)

$qaEngineer = [ProjectTeam]::new(
    "QA Engineer",
    "QA Engineer",
    "Test the PowerShell project to ensure it meets the requirements and is free of bugs. Create and execute test plans, conduct functional and non-functional testing, and report issues.",
    0.6,
    0.9,
    [scriptblock]::Create({
        param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
        $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4" -simpleresponse -OneTimeUserPrompt -Stream $true -LogFolder $script:TeamDiscussionDataFolder
        return $response
    })
)

$documentationSpecialist = [ProjectTeam]::new(
    "Documentation Specialist",
    "Documentation Specialist",
    "Create comprehensive documentation for the PowerShell project, including user guides, developer notes, and installation instructions.",
    0.6,
    0.8,
    [scriptblock]::Create({
        param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
        $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4" -simpleresponse -OneTimeUserPrompt -Stream $true -LogFolder $script:TeamDiscussionDataFolder
        return $response
    })
)

$projectManager = [ProjectTeam]::new(
    "Project Manager",
    "Project Manager",
    "Coordinate the development of the PowerShell project. Manage timelines, facilitate communication between team members, and ensure the project stays on track.",
    0.7,
    0.85,
    [scriptblock]::Create({
        param ($SystemPrompt, $UserPrompt, $Temperature, $TopP)
        $response = Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -Deployment "udtgpt4" -simpleresponse -OneTimeUserPrompt -Stream $true -LogFolder $script:TeamDiscussionDataFolder
        return $response
    })
)

# Link the expert objects to form a team workflow
$requirementsAnalyst.SetNextExpert($systemArchitect)
$systemArchitect.SetNextExpert($powerShellDeveloper)
$powerShellDeveloper.SetNextExpert($qaEngineer)
$qaEngineer.SetNextExpert($documentationSpecialist)
#$documentationSpecialist.SetNextExpert($projectManager)

# Example of starting the process
$response = $requirementsAnalyst.ProcessInput($userInput)

# Log final response to file
$response | Out-File -FilePath (Join-Path $script:TeamDiscussionDataFolder "finalresponse.log")
# Display the final response
Write-Host "Final Response: $response"

# Display the memory of each expert
<#
$requirementsAnalyst.DisplayInfo()
$systemArchitect.DisplayInfo()
$powerShellDeveloper.DisplayInfo()
$qaEngineer.DisplayInfo()
$documentationSpecialist.DisplayInfo()
$projectManager.DisplayInfo()
#>
