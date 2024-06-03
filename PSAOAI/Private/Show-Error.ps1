# Function to handle and display errors
function Show-Error {
    <#
    .SYNOPSIS
    Manages and outputs errors.
    
    .DESCRIPTION
    This function manages any errors that arise during the script's execution. It outputs the error details to the console for debugging.
    
    .PARAMETER ErrorVar
    The error variable that holds the error details. This parameter is required.
    
    .EXAMPLE
    Show-Error -ErrorVar $errorVar
    
    .OUTPUTS
    None. This function manages the errors and outputs the error details to the console.

    .NOTES
        Author: Wojciech Napierala
        Date: 2024-04

    #> 
    param(
        [Parameter(Mandatory = $true)]
        $ErrorVar # The error variable that holds the error details
    )
    
    $ErrorVar.tostring()| ConvertTo-Json

    # Output the error details (file, line, character, and message) to the console if any error arises during the process
    Write-Host "[e] Error in file: $($ErrorVar.InvocationInfo.ScriptName)" -ForegroundColor DarkRed
    Write-Host "[e] Error in line: $($ErrorVar.InvocationInfo.ScriptLineNumber)" -ForegroundColor DarkRed
    Write-Host "[e] Error at char: $($ErrorVar.InvocationInfo.OffsetInLine)" -ForegroundColor DarkRed
    Write-Host "[e] An error occurred: " -NoNewline -ForegroundColor DarkRed
    Write-Host "$($ErrorVar.Exception.Message)" -ForegroundColor DarkRed
    
    # Manage specific types of exceptions for more detailed error messages
    if ($ErrorVar.Exception -is [System.Net.WebException]) {
        # Manage WebException and output the status code
        Write-Host "[e] WebException: $($ErrorVar.Exception.Response.StatusCode)" -ForegroundColor DarkRed
    }
    elseif ($ErrorVar.Exception -is [System.IO.IOException]) {
        # Manage IOException and output the IO error
        Write-Host "[e] IOException: $($ErrorVar.Exception.IOError)" -ForegroundColor DarkRed
    }
    elseif ($ErrorVar.Exception -is [System.ArgumentException]) {
        # Manage ArgumentException and output the parameter name that caused the exception
        Write-Host "[e] ArgumentException: $($ErrorVar.Exception.ParamName)" -ForegroundColor DarkRed
    }
    else {
        # Manage unknown error types and output the full type name
        Write-Host "[e] Unknown error type: $($ErrorVar.Exception.GetType().FullName)" -ForegroundColor DarkRed
    }
    Write-Host "" # Output an empty line for better readability
}
