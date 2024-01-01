# This function serves as a wrapper for invoking Azure OpenAI services
function Invoke-AzureOpenAIWrapper {
    <#
    .SYNOPSIS
    This script serves as a wrapper for invoking Azure OpenAI services.

    .DESCRIPTION
    This script allows users to interact with various Azure OpenAI services. It imports necessary functions from other scripts, 
    handles the user prompt, calls the appropriate Azure OpenAI function based on the input parameters, and handles any errors that may occur. 
    It also provides options to generate artwork based on the chat output or the initial prompt.

    .PARAMETER serviceName
    The name of the Azure OpenAI service to be invoked. This should correspond to the Azure OpenAI service's unique identifier.

    .PARAMETER Prompt
    The text to be used for invoking the Azure OpenAI service. This can be provided directly or piped in.

    .PARAMETER user
    The username to be used for the service invocation.

    .PARAMETER ApiVersion
    The API version to be used for the service invocation.

    .PARAMETER SystemPromptFileName
    The filename where system prompts are stored.

    .PARAMETER Deployment
    The deployment information for the Azure OpenAI service.

    .PARAMETER model
    The model to be used for the service invocation at Pollinations only. 

    .PARAMETER pollinations
    If this switch is set, the script will generate artwork based on the chat output.

    .PARAMETER pollinationspaint
    If this switch is set, the script will generate artwork based on the initial prompt.

    .PARAMETER ImageLoops
    The number of times to loop the image generation process.

    .EXAMPLE
    PS> .\Invoke-AzureOpenAIWrapper.ps1 -serviceName "serviceName" -Prompt "Hello, world!" -user "user" -ApiVersion "v1" -SystemPromptFileName "ArtFusion2.txt" -Deployment "deployment" -model "pixart" -pollinations -pollinationspaint -ImageLoops 5
    #>

    [CmdletBinding()]
    param (
        # Name of the Azure OpenAI service to be invoked
        [string]$serviceName,

        # Prompt to be used for the service invocation, can be piped in
        [Parameter(ValueFromPipeline = $true)]
        [string]$Prompt,

        # User name for the service invocation
        [string]$user,

        # API version to use for the service invocation
        [string]$ApiVersion,

        # File name for system prompts
        [string]$SystemPromptFileName,

        # Deployment information for the Azure OpenAI service
        [string]$Deployment,

        # Model to be used for the service invocation at Pollinations only
        [ValidateSet("turbo", "playground", "dpo", "dreamshaper", "deliberate", "pixart", "dalle3xl", "formulaxl")]
        [string]$model = "pixart",

        # Switch to trigger pollinations functionality
        [switch]$pollinations,
        [switch]$pollinationspaint,
        [double]$Temperature = 0.6,
        [int]$N = 1,
        [double]$FrequencyPenalty = 0,
        [double]$PresencePenalty = 0,
        [double]$TopP = 0,
        [string]$Stop = $null,

        # Number of times to loop the image generation process
        [int]$ImageLoops = 1
    )

    begin {
        Write-Verbose "Importing necessary functions from other scripts"
        . .\AzureOpenAI-PowerShell\Invoke-AzureOpenAIChatCompletion.ps1
        . .\AzureOpenAI-PowerShell\Invoke-AzureOpenAIDalle3.ps1
        . .\skryptyVoytasa\pollpromptpaint.ps1
        . .\skryptyVoytasa\pollprompt.ps1

        Write-Verbose "Recording the start time of the script"
        $startTime = Get-Date
    }

    # If no prompt is provided, prompt the user for it
    # Call the Invoke-AzureOpenAIChatCompletion function
    # Display the chat output
    # Invoke other Azure OpenAI functions based on the chat output
    # Generate artwork based on the chat output if $pollinations is set
    # Skip further processing if there's no chat output
    # Generate artwork based on the initial prompt if $pollinationspaint is set
    process {    
    
        Write-Verbose "Checking if prompt is provided"
        if (-not $prompt) {
            $prompt = read-Host "Prompt"
        }
        
        Write-Verbose "Calling the Invoke-AzureOpenAIChatCompletion function and removing unnecessary output"
        try {
            $chatOutput = (Invoke-AzureOpenAIChatCompletion -APIVersion $ApiVersion -Endpoint "https://$serviceName.openai.azure.com" -Deployment $Deployment -User $User -Temperature $Temperature -N $N -FrequencyPenalty $FrequencyPenalty -PresencePenalty $PresencePenalty -TopP $TopP -Stop $Stop -Stream $false -OneTimeUserPrompt $prompt -SystemPromptFileName "ArtFusion2.txt").replace("Response assistant (assistant):", "").trim()
        }
        catch {
            Write-Host "Error in Invoke-AzureOpenAIChatCompletion: $_" -ForegroundColor Red
            return
        }


        Write-Verbose "Checking if there's output from the chat completion"
        if ($chatOutput) {
            Write-Verbose "Displaying the chat output"
            Write-Host $chatOutput -ForegroundColor Cyan

            $dallePrompt = $chatOutput + " (remove unsafe elements:1.5)"

            Write-Verbose "Invoking other Azure OpenAI functions based on the chat output"
            try {
                Invoke-AzureOpenAIDALLE3 -serviceName $serviceName -prompt $dallePrompt -ImageLoops $ImageLoops
            }
            catch {
                Write-Host "Error in Invoke-AzureOpenAIDALLE3: $_" -ForegroundColor Red
            }
            Write-Verbose "Checking if the pollinations switch is set"
            if ($pollinations) {
                Write-Verbose "Generating artwork based on the chat output"
                try {
                    Generate-Artwork -model $model -Prompt $chatOutput -Once -ImageLoops $ImageLoops
                }
                catch {
                    Write-Host "Error in Generate-Artwork: $_" -ForegroundColor Red
                }
            }
        }
        else {
            Write-Verbose "Skipping further processing as there's no chat output"
            Write-Host "skipping..." -ForegroundColor DarkRed
        }

        Write-Verbose "Checking if the pollinationspaint switch is set"
        if ($pollinationspaint) {
            Write-Verbose "Generating artwork based on the initial prompt"
            try {
                Generate-ArtworkPaint -model $model -Prompt $prompt -Once -ImageLoops $ImageLoops
            }
            catch {
                Write-Host "Error in Generate-ArtworkPaint: $_" -ForegroundColor Red
            }
        }
        Remove-Variable -Name prompt, chatOutput -ErrorAction SilentlyContinue
    }

    # Record the end time of the script
    # Calculate the total execution time
    # Clean up variables used in the script to free up memory
    end {
        Write-Verbose "Recording the end time of the script and calculating the total execution time"
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalSeconds
        Write-Host "Execution time: $executionTime seconds" -ForegroundColor Yellow

        Remove-Variable -Name startTime, endTime, executionTime -ErrorAction SilentlyContinue
    }
}