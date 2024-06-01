param(
    [string] $Topic = "Create CPU monitoring app",
    [bool] $Stream = $true
)

#region LanguageModelClass
class LanguageModel {
    [string] $name
    [string] $ExpertPrompt
    [string[]] $memory

    LanguageModel([string] $name, $ExpertPrompt) {
        $this.name = $name
        $this.ExpertPrompt = $ExpertPrompt
        $this.memory = @()
    }

    [string] TextCompletion([string] $prompt, [bool] $Stream) {
        try {
            $arguments = @($prompt, 3000, "Precise", $this.name, "udtgpt35turbo", $true)
            $response = Invoke-PSAOAICompletion @arguments -LogFolder $script:TeamDiscussionDataFolder -verbose:$false -Stream $Stream
            $this.memory += $response
            return $response
        }
        catch {
            return "An error occurred while invoking the language model: $_"
        }
    }

    [string] ChatCompletion([string] $SystemPrompt, [string] $UserPrompt, [bool] $Stream) {
        try {
            $arguments = @($SystemPrompt, $UserPrompt, "Precise", $true, $true, $this.name, "udtgpt4turbo")
            $response = Invoke-PSAOAIChatCompletion @arguments -LogFolder $script:TeamDiscussionDataFolder -verbose:$false -Stream $Stream
            $this.memory += $response
            return $response
        }
        catch {
            return "An error occurred while invoking the language model: $_"
        }
    }

    [string[]] GetLastNMemoryElements([int] $n) {
        $lastNElements = ($this.memory | Select-Object -Last $n)
        return $lastNElements
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
$SystemAnalyst = New-Object LanguageModel -ArgumentList "System Analyst", $SystemAnalystPrompt

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
$PowerShellDeveloper = New-Object LanguageModel -ArgumentList "PowerShell Developer", $PowerShellDeveloperPrompt

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
$QualityAssurance = New-Object LanguageModel -ArgumentList "Quality Assurance (QA) Tester", $QualityAssurancePrompt
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

# Assuming Write-Color is a custom function, otherwise use Write-Host for simplicity
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

