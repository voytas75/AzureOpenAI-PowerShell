<#
.SYNOPSIS
    This function transforms any text into a continuous string by replacing newline characters with a space.

.DESCRIPTION
    The Format-ContinuousText function accepts a string as input and returns a string where all newline characters (`r`n) and (`n`) are replaced with a space (" ").

.PARAMETER text
    The text parameter is mandatory and should be a string. This is the text that will be transformed into a continuous string.

.EXAMPLE
    PS C:\> $Text = "Hello,`nWorld!"
    PS C:\> $ContinuousText = Format-ContinuousText -text $Text
    PS C:\> Write-Host $ContinuousText
    Hello, World!

.NOTES
    Author: Wojciech Napierala
    Date: 2024-04
#>
function Format-ContinuousText {
    param (
        [Parameter(Mandatory = $true)]
        [string]$text
    )

    # Replace carriage return and newline characters with a space
    $text = $text -replace "`r`n", " "

    # Replace newline characters with a space and return the result
    return $text -replace "`n", " "
}
