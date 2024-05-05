<#
.SYNOPSIS
    The Entity class in PowerShell represents an entity with specific properties and methods.

.DESCRIPTION
    The Entity class is a representation of an entity with properties such as Name, Role, Description, Skills, GPTType, and GPTModel. 
    This class also includes methods to invoke external functions from other PowerShell modules and to send resources to other entities.

.NOTES
    Author     : Wojciech Napierala
    Date       : 25/04/2024
#>
class Entity {
    # The name of the entity
    [string] $Name
    # The role of the entity
    [string] $Role
    # A description of the entity
    [string] $Description
    # An array of skills that the entity possesses
    [string[]] $Skills
    # The type of GPT used by the entity
    [string] $GPTType
    # The model of GPT used by the entity
    [string] $GPTModel    
    [array] $ConversationHistory
    # The constructor for the Entity class
    Entity(
        [string] $name, 
        [string] $role, 
        [string] $description, 
        [string[]] $skills, 
        [string] $gptType,
        [string] $gptModel        
    ) {
        # Initialize the properties of the entity
        $this.Name = $name
        $this.Role = $role
        $this.Description = $description
        $this.Skills = $skills
        $this.GPTType = $gptType
        $this.GPTModel = $gptModel
    }

    # Method to invoke external function from another PowerShell module
    [string] InvokeCompletion(
        [string] $moduleName, 
        [string] $functionName, 
        [object[]] $arguments, 
        [switch]$Verbose
    ) {
        # Import the module if it's not already imported
        if (-not (Get-Module -Name $moduleName)) {
            Import-Module -Name $moduleName -ErrorAction Stop
        }
        # Invoke the function from the imported module
        return (& $functionName @arguments -Verbose:$Verbose)
    }

    # Method to invoke external function from another PowerShell module
    [string] InvokeChatCompletion([string] $PSmoduleName, [string] $functionName, [object[]] $arguments, [switch]$Verbose) {
        # Import the module if it's not already imported
        if (-not (Get-Module -Name $PSmoduleName)) {
            Import-Module -Name $PSmoduleName -ErrorAction Stop
        }
        # Invoke the function from the imported module
        return (& $functionName @arguments -Verbose:$Verbose)
    }
    
    [string] SendResource(
        [string] $resource, 
        [Entity] $destinationEntity, 
        [string] $PSmoduleName, 
        [string] $functionName
    ) {
        $Message = @"
You act as $($destinationEntity.Description) with skills $($destinationEntity.Skills -join ", ").
"@
        #Your specific task is generate english JSON for a developer to use in code. The specific task is to create a JSON structure for the  "${resource}". The response must be in JSON format ready to be copied and pasted into a code snippet. Every json value must be in english. Modify only the values, in the given JSON example structure: { "ExpertName": "", "Role": "", "Query": "", "Response": "" }
        #
        #Write-Host $message
        #Write-Host $Message
        #Write-Host $resource
        write-Verbose (Shorten-Text $resource)
        # Invoke invokeCompletion to send the resource to the destination entity
        ###$arguments = @($Message, 2000, "Precise", $destinationEntity.name, $destinationEntity.GPTModel, $true)
        ###$response = $destinationEntity.invokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $true)
        $arguments = @($Message, $resource, "Precise", $true, $true, $destinationEntity.name, "udtgpt4")
        $response = $destinationEntity.invokeChatCompletion($PSmoduleName, $functionName, $arguments, $false)
        #Write-Host "Response from $($destinationEntity.Name): $response"
        return $response
    }
    # Method to add an interaction to the conversation history
    [void] AddToConversationHistory([string] $prompt, [string] $response) {
        $interaction = [PSCustomObject]@{
            Prompt   = $prompt
            Response = $response
        }
        $this.ConversationHistory += $interaction
    }

    # Method to add an interaction to the conversation history
    [void] AddToConversationHistory([string] $systemMessage, [string] $userMessage, [string] $response) {
        $interaction = [PSCustomObject]@{
            Prompt   = $($systemMessage+$userMessage)
            Response = $response
        }
        $this.ConversationHistory += $interaction
    }


    # Method to clear the conversation history
    [void] ClearConversationHistory() {
        $this.ConversationHistory = @()
    }

    # Method to retrieve the entire conversation history
    [array] GetConversationHistory() {
        return $this.ConversationHistory
    }

    # Method to retrieve the last n interactions from the conversation history
    [array] GetLastNInteractions([int] $n) {
        if ($n -le 0) {
            return @()
        }
        if ($n -ge $this.ConversationHistory.Count) {
            return $this.ConversationHistory
        }
        $startIndex = $this.ConversationHistory.Count - $n
        return $this.ConversationHistory[$startIndex..($this.ConversationHistory.Count - 1)]
    }

    # Method to save the conversation history to a file
    [void] SaveConversationHistoryToFile([string] $filePath, [string] $type) {
        switch ($type) {
            "CSV" {
                $this.ConversationHistory | Export-Csv -Path $filePath -NoTypeInformation            
            }
            "JSON" {
                $this.ConversationHistory | ConvertTo-Json -Depth 100 | Set-Content $filePath
            }
            Default {}
        }        
    }
}
