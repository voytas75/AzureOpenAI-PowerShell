# Import PS LLM
. .\PSMatrixLLM.ps1

function Invoke-GptPowerShell {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$UserInput,
        
        [int]$MaxTokens = $null,
        
        [double]$Temperature = 0.3,

        [double]$TopP = 0.7,
        [switch]$ExecuteCode,
        [bool]$Stream = $false,
        [string]$LogFolder = [System.IO.Path]::GetTempPath(),
        [int]$MaxRetries = 3,
        [string]$DeploymentChat = "",
        [string]$ollamaModel = "",
        [string]$Provider = "AzureOpenAI"
    )

    # Initialize retry count and success flag
    $retryCount = 0
    $success = $false

    # Define the system prompt
    $systemPrompt = "You are a PowerShell code generator. Respond only with executable PowerShell code, no code block, no explanations."

    # Loop until success or max retries reached
    while (-not $success -and $retryCount -lt $MaxRetries) {
        try {
            # Invoke the LLM chat completion function
            Write-Verbose "Invoking LLM chat completion with provider: $Provider"
            $code = Invoke-LLMChatCompletion -Provider $Provider -SystemPrompt $systemPrompt -UserPrompt $UserInput -Temperature $Temperature -TopP $TopP -MaxTokens $MaxTokens -Stream $Stream -LogFolder $LogFolder -DeploymentChat $DeploymentChat -ollamaModel $ollamaModel

            Write-Host "Generated PowerShell Code (Attempt $($retryCount + 1)):"
            Write-Host $code
            Write-Host ""

            if ($ExecuteCode) {
                Write-Host "Executing code..."
                try {
                    # Execute the generated code
                    $result = Invoke-Expression $code
                    $success = $true
                    Write-Host "Code executed successfully."
                    Write-Host "Result:"
                    return $result
                }
                catch {
                    # Handle execution errors
                    Write-Host "Error occurred during execution:"
                    Write-Host $_.Exception.Message
                    $retryCount++
                    if ($retryCount -lt $MaxRetries) {
                        Write-Host "Retrying..."
                        $UserInput += "`nThe previous attempt resulted in the following error: $($_.Exception.Message). Please fix the code and try again."
                    }
                    else {
                        Write-Host "Max retries reached. Unable to execute code successfully."
                    }
                }
            }
            else {
                Write-Host "Generated code (not executed):"
                Write-Host $code
                Write-Host "To execute this code, run the command again with the -ExecuteCode switch."
                break
            }
        }
        catch {
            # Handle errors from LLM chat completion
            Write-Host "Error occurred during LLM chat completion:"
            Write-Host $_.Exception.Message
            $retryCount++
            if ($retryCount -lt $MaxRetries) {
                Write-Host "Retrying..."
            }
            else {
                Write-Host "Max retries reached. Unable to generate code successfully."
            }
        }
    }
}