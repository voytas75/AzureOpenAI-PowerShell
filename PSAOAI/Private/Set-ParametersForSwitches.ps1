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
        [switch]$UltraPrecise,
        [switch]$Precise,
        [switch]$Focused,
        [switch]$Balanced,
        [switch]$Informative,
        [switch]$Creative,
        [Switch]$Surreal

    )
    
    # Initialize parameters with default values
    $parameters = @{
        #Focused
        'Temperature' = 0.2
        'TopP'        = 0.8
    }

    # If Creative switch is enabled, adjust parameters for creative output
    if ($Creative) {
        $parameters['Temperature'] = 0.7
        $parameters['TopP'] = 0.8
    }
    elseif ($Surreal) {
        $parameters['Temperature'] = 1.0
        $parameters['TopP'] = 0.1
    }
    elseif ($UltraPrecise) {
        $parameters['Temperature'] = 0.1
        $parameters['TopP'] = 0.95
    }
    elseif ($Focused) {
        $parameters['Temperature'] = 0.2
        $parameters['TopP'] = 0.8
    }
    elseif ($Balanced) {
        $parameters['Temperature'] = 0.5
        $parameters['TopP'] = 0.5
    }
    elseif ($Informative) {
        $parameters['Temperature'] = 0.4
        $parameters['TopP'] = 0.7
    }
    # If Precise switch is enabled, adjust parameters for precise output
    elseif ($Precise) {
        $parameters['Temperature'] = 0.2
        $parameters['TopP'] = 0.9
    }

    # Return the adjusted parameters
    return $parameters
}
