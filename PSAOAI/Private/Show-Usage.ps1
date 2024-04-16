# Function to output the usage
function Show-Usage {
    <#
        .SYNOPSIS
        Outputs the usage statistics of the API call.
        
        .DESCRIPTION
        This function takes in a usage object and prints the usage statistics to the console in a verbose manner. 
        The usage object typically contains information about the total tokens in the API call and the total tokens used.
        
        .PARAMETER usage
        The usage object to be displayed. This parameter is mandatory.
        
        .EXAMPLE
        Show-Usage -usage $response.usage
        
        .OUTPUTS
        String. This function outputs the usage statistics to the console and returns a string representation of the usage.

        .NOTES
        Author: Wojciech Napierala
        Date: 2024-04

        #> 
    param(
        [Parameter(Mandatory = $true)]
        [System.Object]$usage # The usage object to display
    )

    # Convert the usage object to a string and write it to the console in a verbose manner
    Write-Verbose ($usage | Out-String)
    Write-Verbose (($usage | gm) | Out-String)

    # Return a string representation of the usage
    $usageData = $usage
    return "Usage:`n$usageData"
}
