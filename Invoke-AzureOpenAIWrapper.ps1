function Invoke-AzureOpenAIWrapper {
    [CmdletBinding()]
    param (
        [string]$serviceName,
        [Parameter(ValueFromPipeline = $true)]
        [string]$Prompt,
        [string]$model = 'dalle3',
        [string]$user,
        [string]$ApiVersion = "2023-12-01-preview",
        [string]$SavePath = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyPictures),
        [double]$PresencePenalty = 0,
        [string]$Stop = $null,
        [bool]$Stream = $false,
        [string]$SystemPromptFileName,
        [string]$Deployment
    )

    . .\AzureOpenAI-PowerShell\Invoke-AzureOpenAIChatCompletion.ps1
    . .\AzureOpenAI-PowerShell\Invoke-AzureOpenAIDalle3.ps1; 

    $endpoint ="https://$serviceName.openai.azure.com"
    # Call Invoke-AzureOpenAIChatCompletion function and store the output
    $chatOutput = Invoke-AzureOpenAIChatCompletion -APIVersion $ApiVersion -Endpoint $endpoint  -Deployment $Deployment -User $User -Temperature 0.6 -N 1 -FrequencyPenalty 0 -PresencePenalty 0 -TopP 0 -Stop $null -Stream $false -OneTimeUserPrompt $prompt -SystemPromptFileName "ArtFusion.txt"

    Invoke-AzureOpenAIDALLE3 -serviceName $serviceName -prompt $chatOutput
}
