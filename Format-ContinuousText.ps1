function Format-ContinuousText {
    # Define the parameters for the function
    param (
        # The text parameter is mandatory and should be a string
        [Parameter(Mandatory = $true)]
        [string]$text
    )

    # This function is designed to transform any text into a continuous string by replacing newline characters with a space.
    # It accepts a string as input and returns a string where all newline characters (`r`n) and (`n`) are replaced with a space (" ").

    # The `-replace` operator is used to replace all newline characters with a space.
    # The result is returned as the output of the function.

    $text = $text -replace "`r`n", " " # Replace carriage return and newline characters
    return $text -replace "`n", " " # Replace newline characters
}
