function Invoke-AzureOpenAIWrapper {
    [CmdletBinding()]
    param (
        [string]$serviceName,

        [Parameter(ValueFromPipeline = $true)]
        [string]$Prompt,

        [string]$user,

        [string]$ApiVersion,

        [string]$SystemPromptFileName,

        [string]$Deployment,

        [ValidateSet("turbo", "playground", "dpo", "dreamshaper", "deliberate", "pixart", "dalle3xl", "formulaxl")]
        [string]$model = "pixart",

        [switch]$pollinations,

        [switch]$pollinationspaint
    )
    begin {
        . .\AzureOpenAI-PowerShell\Invoke-AzureOpenAIChatCompletion.ps1
        . .\AzureOpenAI-PowerShell\Invoke-AzureOpenAIDalle3.ps1
        . .\skryptyVoytasa\pollpromptpaint.ps1
        . .\skryptyVoytasa\pollprompt.ps1
    }
    process {        

        if (-not $prompt) {
            $prompt = read-Host "Prompt"
        }
        # Call Invoke-AzureOpenAIChatCompletion function and remove a given string from output
        $chatOutput = (Invoke-AzureOpenAIChatCompletion -APIVersion $ApiVersion -Endpoint "https://$serviceName.openai.azure.com" -Deployment $Deployment -User $User -Temperature 0.6 -N 1 -FrequencyPenalty 0 -PresencePenalty 0 -TopP 0 -Stop $null -Stream $false -OneTimeUserPrompt $prompt -SystemPromptFileName "ArtFusion2.txt").replace("Response assistant (assistant):", "").trim()
    
        if ($chatOutput) {

            Write-Host $chatOutput -ForegroundColor Cyan

            Invoke-AzureOpenAIDALLE3 -serviceName $serviceName -prompt $chatOutput
            if ($pollinations) {
                Generate-Artwork -model $model -Prompt $chatOutput -Once
            }
        }
        else {
            Write-Host "skipping..." -ForegroundColor DarkRed
        }
        if ($pollinationspaint) {
            Generate-ArtworkPaint -model $model -Prompt $prompt -Once
        }
    }
}
