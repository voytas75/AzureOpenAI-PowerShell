function Format-Error {
    <#
.SYNOPSIS
This function formats and outputs the provided error record.

.DESCRIPTION
The Format-Error function takes in an ErrorRecord object and outputs it. 
This can be used for better error handling and logging in scripts.

.PARAMETER ErrorVar
The ErrorRecord object to be formatted and outputted. This parameter is mandatory.

.EXAMPLE
Format-Error -ErrorVar $Error
#>
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorVar
    )

    # Output the ErrorRecord object
    Write-Output $ErrorVar
}
