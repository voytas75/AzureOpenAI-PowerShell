<#
.SYNOPSIS
This function retrieves the API versions from the Azure OpenAI GitHub repository.

.DESCRIPTION
The Get-APIVersion function sends a GET request to the Azure OpenAI GitHub repository and retrieves the API versions from the 'preview' and 'stable' folders. It then sorts the API versions by date, ignoring the '-preview' suffix, and returns the sorted array of API versions.

.PARAMETER Stable
This switch parameter indicates whether to retrieve the API versions from the 'stable' folder.

.PARAMETER Preview
This switch parameter indicates whether to retrieve the API versions from the 'preview' folder.

.EXAMPLE
PS> Get-APIVersion -Stable -Preview

This command retrieves the API versions from both the 'stable' and 'preview' folders.

.EXAMPLE 
PS> Get-APIVersion -Stable

This example retrieves all stable API versions without including preview ones.

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS
System.Array.
An array of strings containing sorted list of version names based on their release dates in descending order is returned by this command.

.NOTES 
Author: Voytas75
Date: 04.2024
GitHub Repository URL: https://github.com/voytas75/AzureOpenAI-PowerShell/
#>
function Get-APIVersion {
    param (
        [Parameter(Mandatory=$false)]
        [switch]$Stable,
        [Parameter(Mandatory=$false)]
        [switch]$Preview
    )

    # Define the URLs of the Azure OpenAI GitHub repository for 'preview' and 'stable' folders
    $urlPreview = "https://api.github.com/repos/Azure/azure-rest-api-specs/contents/specification/cognitiveservices/data-plane/AzureOpenAI/inference/preview"
    $urlStable = "https://api.github.com/repos/Azure/azure-rest-api-specs/contents/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable"

    # Initialize an empty array to store the API versions
    $apiVersions = @()

    # If neither Stable nor Preview is specified, default to retrieving from both folders
    if (-not $Stable -and -not $Preview) {
        $Stable = $true
        $Preview = $true
    }

    # If Preview is specified, send a GET request to the 'preview' URL and add the API versions to the array
    if ($Preview) {
        $responsePreview = Invoke-RestMethod -Uri $urlPreview -Method Get
        foreach ($file in $responsePreview) {
            # If the file is a directory (i.e., an API version)
            if ($file.type -eq "dir") {
                # Add the name of the directory (i.e., the API version) to the array
                $apiVersions += $file.Name
            }
        }
    }

    # If Stable is specified, send a GET request to the 'stable' URL and add the API versions to the array
    if ($Stable) {
        $responseStable = Invoke-RestMethod -Uri $urlStable -Method Get
        foreach ($file in $responseStable) {
            # If the file is a directory (i.e., an API version)
            if ($file.type -eq "dir") {
                # Add the name of the directory (i.e., the API version) to the array
                $apiVersions += $file.Name
            }
        }
    }

    # Sort the API versions by date, ignoring the '-preview' suffix
    $sortedApiVersions = $apiVersions | Sort-Object { [DateTime]($_ -replace '-preview', '') } -Descending

    # Return the sorted array of API versions
    return $sortedApiVersions
}
