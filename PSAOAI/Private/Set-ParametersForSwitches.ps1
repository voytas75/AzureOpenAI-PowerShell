function Set-ParametersForSwitches {
    <#
    .SYNOPSIS
    This function adjusts the 'Temperature' and 'TopP' parameters based on the provided switches.

    .DESCRIPTION
    This function sets the 'Temperature' and 'TopP' parameters to predefined values based on the state of the 'Creative' or 'Precise' switch. 
    If 'Creative' is enabled, 'Temperature' is set to 0.7 and 'TopP' to 0.95. 
    If 'Precise' is enabled, 'Temperature' is set to 0.3 and 'TopP' to 0.8.

    .PARAMETER Creative
    A switch parameter. When enabled, it sets the parameters for a more creative output.

    .PARAMETER Precise
    A switch parameter. When enabled, it sets the parameters for a more precise output.

    .OUTPUTS
    Outputs a Hashtable of the adjusted parameters.

    .NOTES
        Author: Wojciech Napierala
        Date: 2024-04

    #>
    param(
        [switch]$Creative,
        [switch]$Precise
    )
    
    # Initialize parameters with default values
    $parameters = @{
        'Temperature' = 1.0
        'TopP'        = 1.0
    }

    # If Creative switch is enabled, adjust parameters for creative output
    if ($Creative) {
        $parameters['Temperature'] = 0.7
        $parameters['TopP'] = 0.95
    }
    # If Precise switch is enabled, adjust parameters for precise output
    elseif ($Precise) {
        $parameters['Temperature'] = 0.3
        $parameters['TopP'] = 0.8
    }

    # Return the adjusted parameters
    return $parameters
}
