<#
.SYNOPSIS
    This is a class definition for an Entity in PowerShell.

.DESCRIPTION
    The Entity class represents an entity with properties like Name, Role, Description, Skills, GPTType, and GPTModel.
    It also includes a method to invoke external functions from other PowerShell modules.

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

    # Method to verify the class
    [string] VerifyClass() {
        # Check if the class properties are valid
        if ($this.Name -and $this.Role -and $this.Description -and $this.Skills -and $this.GPTType -and $this.GPTModel) {
            return "OK"
        } else {
            throw "Invalid class properties"
        }
    }

    # Method to invoke external function from another PowerShell module
    [string] InvokeCompletion([string] $moduleName, [string] $functionName, [object[]] $arguments, [switch]$Verbose) {
        # Import the module if it's not already imported
        if (-not (Get-Module -Name $moduleName)) {
            Import-Module -Name $moduleName -ErrorAction Stop
        }
        # Invoke the function from the imported module
        return (& $functionName @arguments -Verbose:$Verbose)
    }

    # Method to invoke external function from another PowerShell module
    [string] InvokeChatCompletion([string] $moduleName, [string] $functionName, [object[]] $arguments, [switch]$Verbose) {
        # Import the module if it's not already imported
        if (-not (Get-Module -Name $moduleName)) {
            Import-Module -Name $moduleName -ErrorAction Stop
        }
        # Invoke the function from the imported module
        return (& $functionName @arguments -Verbose:$Verbose)
    }
    
}
