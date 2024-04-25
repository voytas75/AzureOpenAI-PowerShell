class Entity {
    [string] $Name
    [string] $Role
    [string] $Description
    [string[]] $Skills
    [string] $GPTType
    [string] $GPTModel

    Entity(
        [string] $name, 
        [string] $role, 
        [string] $description, 
        [string[]] $skills, 
        [string] $gptType,
        [string] $gptModel
    ) {
        $this.Name = $name
        $this.Role = $role
        $this.Description = $description
        $this.Skills = $skills
        $this.GPTType = $gptType
        $this.GPTModel = $gptModel
    }

    # Method to invoke external function from another PowerShell module
    [string] InvokeCompletion([string] $moduleName, [string] $functionName, [object[]] $arguments) {
        # Import the module
        if (-not (Get-Module -Name $moduleName)) {
            Import-Module -Name $moduleName -ErrorAction Stop
        }
        # Invoke the function
        return (& $functionName @arguments)
    }
}
