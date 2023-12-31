# This function serves as a wrapper for invoking Azure OpenAI services
function Invoke-AzureOpenAIWrapper {
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

        # Switch to trigger pollinations painting functionality
        [switch]$pollinationspaint
    )

    # Import the necessary functions from other scripts
    # Record the start time of the script
    begin {
        # Import the necessary functions from other scripts
        . .\AzureOpenAI-PowerShell\Invoke-AzureOpenAIChatCompletion.ps1
        . .\AzureOpenAI-PowerShell\Invoke-AzureOpenAIDalle3.ps1
        . .\skryptyVoytasa\pollpromptpaint.ps1
        . .\skryptyVoytasa\pollprompt.ps1

        # Record the start time of the script
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
        # If no prompt is provided, prompt the user for it
        if (-not $prompt) {
            $prompt = read-Host "Prompt"
        }
        
        # Call the Invoke-AzureOpenAIChatCompletion function and remove unnecessary output
        # Trim the output to remove leading and trailing whitespace
        $chatOutput = (Invoke-AzureOpenAIChatCompletion -APIVersion $ApiVersion -Endpoint "https://$serviceName.openai.azure.com" -Deployment $Deployment -User $User -Temperature 0.6 -N 1 -FrequencyPenalty 0 -PresencePenalty 0 -TopP 0 -Stop $null -Stream $false -OneTimeUserPrompt $prompt -SystemPromptFileName "ArtFusion2.txt").replace("Response assistant (assistant):", "").trim()
    
        # If there's output from the chat completion, process it further
        if ($chatOutput) {
            # Display the chat output
            Write-Host $chatOutput -ForegroundColor Cyan

            # Invoke other Azure OpenAI functions based on the chat output
            Invoke-AzureOpenAIDALLE3 -serviceName $serviceName -prompt $chatOutput
            # If the pollinations switch is set, generate artwork based on the chat output
            if ($pollinations) {
                Generate-Artwork -model $model -Prompt $chatOutput -Once
            }
        }
        else {
            Write-Host "skipping..." -ForegroundColor DarkRed
        }

        # If the pollinationspaint switch is set, generate artwork based on the initial prompt
        if ($pollinationspaint) {
            Generate-ArtworkPaint -model $model -Prompt $prompt -Once
        }
    }

    # Record the end time of the script
    # Calculate the total execution time
    # Clean up variables used in the script to free up memory
    end {
        # Record the end time of the script and calculate the total execution time
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalSeconds
        Write-Host "Execution time: $executionTime seconds" -ForegroundColor Yellow

        # Clean up variables used in the script to free up memory
        Remove-Variable -Name prompt, chatOutput, startTime, endTime, executionTime -ErrorAction SilentlyContinue
    }
}
