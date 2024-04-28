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
I am $($this.Name) and my role is $($this.Role). My skills are: $($this.Skills -join ", "). I have request to you.
You act as $($destinationEntity.Role) named $($destinationEntity.Name). Description of your role is '$($destinationEntity.Description)'. Your skills are: $($destinationEntity.Skills -join ", "). Your specific task is to refer to the following description: "${resource}" in the following scope: Ask Open-Ended Questionsto. You MUST answer in a natural, human-like manner, providing a concise yet comprehensive explanation.         
"@
#Your specific task is generate english JSON for a developer to use in code. The specific task is to create a JSON structure for the  "${resource}". The response must be in JSON format ready to be copied and pasted into a code snippet. Every json value must be in english. Modify only the values, in the given JSON example structure: { "ExpertName": "", "Role": "", "Query": "", "Response": "" }
#
        #Write-Host $message

        write-host (Shorten-Text $resource)
        # Invoke invokeCompletion to send the resource to the destination entity
        $arguments = @($resource, 800, "Precise", $destinationEntity.name, $destinationEntity.GPTModel, $true)
        $response = $destinationEntity.invokeCompletion("PSAOAI", "Invoke-PSAOAICompletion", $arguments, $false)
        #Write-Host "Response from $($destinationEntity.Name): $response"
        return $response
    }
}
