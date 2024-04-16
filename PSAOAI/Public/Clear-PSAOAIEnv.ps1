function Clear-PSAOAIEnv {
    <#
    .SYNOPSIS
    This function is designed to clear all Azure OpenAI API environment variables.

    .DESCRIPTION
    The Clear-PSAOAIEnv function is responsible for resetting the values of the Azure OpenAI API environment variables to null. If an error is encountered during this process, the function will catch the exception and provide a detailed error message to the user.

    .EXAMPLE
    Clear-PSAOAIEnv

    .NOTES
    Author: Wojciech Napierala
    Date:   2023-06
    #>    
    param()
    # Informing the user about the upcoming operation
    Write-Host "This operation will clear all $script:ModuleName environment variables. Please ensure you have backed up any important data before proceeding."
    try {
        # Initiating a job to clear the environment variables associated with Azure OpenAI API
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
            # Setting the environment variable to 'purging' before setting it to null
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

        # Displaying a "." every 0.5 seconds to indicate that the job is still running
        while ($job.State -eq "Running") {
            Write-Host "." -NoNewline -ForegroundColor Blue
            Start-Sleep -Milliseconds 1000
        }
        Write-Host ""
        Write-Host ""

        # Receiving the job and removing it from the job queue
        Receive-Job -Job $job
        Remove-Job -Job $job

        # Notifying the user about the successful deletion of the environment variables
        Write-Host "Environment variables for Azure API have been deleted successfully."
        Write-Host ""
    }
    catch {
        # Providing detailed error information if any errors occurred during the deletion of the environment variables
        Write-Host "An error occurred while trying to delete Azure API environment variables. Please verify your permissions and try again."
        Show-Error -ErrorVar $_
        Write-Host ""
    }
}
