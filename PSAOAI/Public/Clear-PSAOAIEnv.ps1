function Clear-PSAOAIEnv {
    <#
    .SYNOPSIS
    This function clears the Azure OpenAI API environment variables.

    .DESCRIPTION
    The Clear-AzureOpenAIAPIEnv function clears the values of the Azure OpenAI API environment variables. If an error occurs during the process, it provides an error message to the user.

    .EXAMPLE
    Clear-AzureOpenAIAPIEnv
    #>    param()
    try {
        # Start a job to clear the environment variables related to Azure OpenAI API
        $job = Start-Job -ScriptBlock {
            [System.Environment]::SetEnvironmentVariable("API_AZURE_OPENAI_APIVERSION", "", "User")
            [System.Environment]::SetEnvironmentVariable("API_AZURE_OPENAI_DEPLOYMENT", "", "User")
            [System.Environment]::SetEnvironmentVariable("API_AZURE_OPENAI_KEY", "", "User")
            [System.Environment]::SetEnvironmentVariable("API_AZURE_OPENAI_Endpoint", "", "User")
        }

        # Show "." every 0.5 seconds while the job is running
        while ($job.State -eq "Running") {
            Write-Host "." -NoNewline -ForegroundColor Blue
            Start-Sleep -Milliseconds 1000
    }

        # Receive the job and remove it
        Receive-Job -Job $job
        Remove-Job -Job $job

        # Inform the user about the successful deletion of the environment variables
        Write-Host "`nEnvironment variables for Azure API have been deleted successfully."
    }
    catch {
        # Inform the user about any errors occurred during the deletion of the environment variables
        Write-Host "An error occurred while trying to delete Azure API environment variables. Please check your permissions and try again."
    }
}
