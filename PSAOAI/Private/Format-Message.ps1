    function Format-Message {
        <#
    .SYNOPSIS
    This function formats the provided message by removing non-ASCII characters.

    .DESCRIPTION
    The Format-Message function takes in a string message and returns a version of the message with all non-ASCII characters removed. 
    This can be used to ensure that the message can be properly displayed in environments that only support ASCII characters.

    .PARAMETER Message
    The string message to be formatted. This parameter is mandatory.

    .EXAMPLE
    $userMessage = Format-Message -Message $OneTimeUserPrompt
    #>
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message
        )

        # Remove non-ASCII characters from the message
        return [System.Text.RegularExpressions.Regex]::Replace($Message, "[^\x00-\x7F]", "")
    }
