function Clear-PSAOAIEnv {
    <#
    .SYNOPSIS
    This function clears the Azure OpenAI API environment variables.

    .DESCRIPTION
    The Clear-AzureOpenAIAPIEnv function clears the values of the Azure OpenAI API environment variables. If an error occurs during the process, it provides an error message to the user.

    .EXAMPLE
    Clear-AzureOpenAIAPIEnv
    #>    param()
    Write-Host "This operation will clear all $script:ModuleName environment variables. Make sure to backup any important data before proceeding."
    try {
        # Start a job to clear the environment variables related to Azure OpenAI API
        $job = Start-Job -ScriptBlock {
            param (
                $apiversion,
                $CCDeploy,
                $CDeploy,
                $D3Deploy,
                $Key,
                $Endpoint
            )
            $purgeText = "purging"
            [System.Environment]::SetEnvironmentVariable($apiversion, $purgeText, "User")
            [System.Environment]::SetEnvironmentVariable($apiversion, $null, "User")
            Write-Host "Purged $apiversion"
            [System.Environment]::SetEnvironmentVariable($CCDeploy, $purgeText, "User")
            [System.Environment]::SetEnvironmentVariable($CCDeploy, $null, "User")
            Write-Host "Purged $CCDeploy"
            [System.Environment]::SetEnvironmentVariable($CDeploy, $purgeText, "User")
            [System.Environment]::SetEnvironmentVariable($CDeploy, $null, "User")
            Write-Host "Purged $CDeploy"
            [System.Environment]::SetEnvironmentVariable($D3Deploy, $purgeText, "User")
            [System.Environment]::SetEnvironmentVariable($D3Deploy, $null, "User")
            Write-Host "Purged $D3Deploy"
            [System.Environment]::SetEnvironmentVariable($Key, $purgeText, "User")
            [System.Environment]::SetEnvironmentVariable($Key, $null, "User")
            Write-Host "Purged $Key"
            [System.Environment]::SetEnvironmentVariable($Endpoint, $purgeText, "User")
            [System.Environment]::SetEnvironmentVariable($Endpoint, $null, "User")
            Write-Host "Purged $Endpoint"
        } -ErrorAction Stop -ArgumentList $script:API_AZURE_OPENAI_APIVERSION, `
            $script:API_AZURE_OPENAI_CC_DEPLOYMENT, `
            $script:API_AZURE_OPENAI_C_DEPLOYMENT, `
            $script:API_AZURE_OPENAI_D3_DEPLOYMENT, `
            $script:API_AZURE_OPENAI_KEY, `
            $script:API_AZURE_OPENAI_Endpoint

        # Show "." every 0.5 seconds while the job is running
        while ($job.State -eq "Running") {
            Write-Host "." -NoNewline -ForegroundColor Blue
            Start-Sleep -Milliseconds 1000
        }
        Write-Host ""
        Write-Host ""

        # Receive the job and remove it
        Receive-Job -Job $job
        Remove-Job -Job $job

        # Inform the user about the successful deletion of the environment variables
        Write-Host "Environment variables for Azure API have been deleted successfully."
        Write-Host ""
    }
    catch {
        # Inform the user about any errors occurred during the deletion of the environment variables
        Write-Host "An error occurred while trying to delete Azure API environment variables. Please check your permissions and try again."
        Show-Error -ErrorVar $_
        Write-Host ""
    }
}
