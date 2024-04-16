<#
.SYNOPSIS
This function retrieves all user environment variables that start with "PSAOAI".

.DESCRIPTION
The Get-PSAOAIEnv function uses the .NET Environment class to get all user environment variables. 
It then filters these variables to only include those that start with "PSAOAI". 
The resulting list of variables is then formatted for display.

.OUTPUTS
System.Collections.DictionaryEntry. Outputs a list of user environment variables that start with "PSAOAI".

.NOTES
    Author: Wojciech Napierala
    Date: 2024-04
#>
function Get-PSAOAIEnv {
    param ()
    
    # Get all user environment variables using .NET Environment class
    # Filter the variables to only include those that start with "PSAOAI"
    # Format the resulting list for display
    ([environment]::GetEnvironmentVariables("user")).GetEnumerator() | Where-Object { $_.Key -like "PSAOAI*" } | Format-List
}