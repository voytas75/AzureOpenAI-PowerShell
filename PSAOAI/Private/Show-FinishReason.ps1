    # Function to display the reason for ending the conversation
    function Show-FinishReason {
        <#
        .SYNOPSIS
        Displays the reason for ending the conversation.
        
        .DESCRIPTION
        The Show-FinishReason function is used to print the reason for ending the conversation to the console. This is typically used in chatbot interactions to indicate why the conversation was terminated.
        
        .PARAMETER finishReason
        The reason for ending the conversation. This parameter is mandatory and should be a string.
        
        .EXAMPLE
        Show-FinishReason -finishReason "End of conversation"
        This example shows how to use the Show-FinishReason function to display "End of conversation" as the reason for ending the conversation.
        
        .OUTPUTS
        None. This function does not return any output. It only prints the finish reason to the console.
        #> 
        param(
            [Parameter(Mandatory = $true)]
            [string]$finishReason # The reason for ending the conversation
        )
    
        # Print an empty line to the console for better readability
        Write-Output ""
        # Print the finish reason to the console
        Write-Output "(Finish reason: $finishReason)"
    }
