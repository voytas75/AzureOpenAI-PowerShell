<#PSScriptInfo

.VERSION 1.0

.GUID df4d3a0f-e09f-4410-826e-23b8c2c0bff8

.AUTHOR Voytas

.COMPANYNAME

.COPYRIGHT

.TAGS AZURE,OpenAI,Artwork,Image,pollinations

.LICENSEURI

.PROJECTURI https://github.com/voytas75/AzureOpenAI-PowerShell/tree/master/PSAOAIWrapper

.ICONURI

.EXTERNALMODULEDEPENDENCIES PSAOAI

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<#

.DESCRIPTION
 This script serves as a wrapper for invoking Azure OpenAI and pollinations.ai services.

 #>
 
 Param()


# This function serves as a wrapper for invoking Azure OpenAI services
function Invoke-AzureOpenAIWrapper {
    <#
    .SYNOPSIS
    This script serves as a wrapper for invoking Azure OpenAI services.

    .DESCRIPTION
    This script allows users to interact with various Azure OpenAI services. It imports necessary functions from other scripts, 
    handles the user prompt, calls the appropriate Azure OpenAI function based on the input parameters, and handles any errors that may occur. 
    It also provides options to generate artwork based on the chat output or the initial prompt.

    .PARAMETER serviceName
    The name of the Azure OpenAI service to be invoked. This should correspond to the Azure OpenAI service's unique identifier.

    .PARAMETER Prompt
    The text to be used for invoking the Azure OpenAI service. This can be provided directly or piped in.

    .PARAMETER user
    The username to be used for the service invocation.

    .PARAMETER ApiVersion
    The API version to be used for the service invocation.

    .PARAMETER SystemPromptFileName
    The filename where system prompts are stored.

    .PARAMETER Deployment
    The deployment information for the Azure OpenAI service.

    .PARAMETER model
    The model to be used for the service invocation at Pollinations only. 

    .PARAMETER pollinations
    If this switch is set, the script will generate artwork based on the chat output.

    .PARAMETER pollinationspaint
    If this switch is set, the script will generate artwork based on the initial prompt.

    .PARAMETER ImageLoops
    The number of times to loop the image generation process.

    .EXAMPLE
    PS> .\Invoke-AzureOpenAIWrapper.ps1 -serviceName "serviceName" -Prompt "Hello, world!" -user "user" -ApiVersion "v1" -SystemPromptFileName "ArtFusion2.txt" -Deployment "deployment" -model "pixart" -pollinations -pollinationspaint -ImageLoops 5
    #>

    [CmdletBinding()]
    param (
        # Name of the Azure OpenAI service to be invoked
        [string]$serviceName,

        # Prompt to be used for the service invocation, can be piped in
        [Parameter(ValueFromPipeline = $true)]
        [string]$Prompt,

        # User name for the service invocation
        [string]$user,

        # API version to use for the service invocation
        [string]$ApiVersion,

        # File name for system prompts
        [string]$SystemPromptFileName,

        # Deployment information for the Azure OpenAI service
        [string]$Deployment,

        # Model to be used for the service invocation at Pollinations only
        [ValidateSet("swizz8", "dreamshaper", "deliberate", "juggernaut")]
        [string]$model,

        [switch]$AzureOpenAIImageGenerate,

        # Switch to trigger pollinations functionality
        [switch]$pollinations,

        [switch]$pollinationspaint,

        [double]$Temperature = 0.6,

        [int]$N = 1,

        [double]$FrequencyPenalty = 0,

        [double]$PresencePenalty = 0,

        [double]$TopP = 0,

        [string]$Stop = $null,

        # Number of times to loop the image generation process
        [int]$ImageLoops = 1,

        [int]$seed,

        [string]$negative,

        [ValidateSet("1024x1024", "1792x1024", "1024x1792")]
        [string]$size = "1792x1024"

    )

    begin {
        Write-Verbose "Importing necessary functions from other scripts"
        import-module PSAOAI
        #. .\skryptyVoytasa\pollpromptpaint.ps1
        #. .\skryptyVoytasa\pollprompt.ps1

        Write-Verbose "Recording the start time of the script"
        $startTime = Get-Date
    }

    # If no prompt is provided, prompt the user for it
    # Call the Invoke-AzureOpenAIChatCompletion function
    # Display the chat output
    # Invoke other Azure OpenAI functions based on the chat output
    # Generate artwork based on the chat output if $pollinations is set
    # Skip further processing if there's no chat output
    # Generate artwork based on the initial prompt if $pollinationspaint is set
    process {    
    
        $systemPrompt = @"
###Instruction###
Your role is as an Art Fusion Expert. I will provide initial word or description of elements and you start Proceure. The main task is to create a description of the prompt to generate the image with procedure: 
    1. Randomly choose a style and an artist from input data. Style chosen must not be in line with the artist! 
    2. Prepare an initial baseline description for the creator of image.
    3. Exclude from description: ugly,  deformed,  noisy,  blurry,  distorted,  out of focus,  bad anatomy,  extra limbs,  poorly drawn face,  poorly drawn hands,  missing fingers. 
    4. Input data:
        1. Styles: Early Renaissance, High Renaissance, Baroque, Early Netherlandish, Dutch Golden Age, Impressionism, Post-Impressionism, Expressionism, Abstract Expressionism, Surrealism, Pop Art, Neo-Expressionism, Abstract, Art Nouveau, Cubism, Dadaism, Fauvism, Minimalism, Realism, Renaissance, Rococo, Symbolism, Pointillism, Neoclassicism, Romanticism, Constructivism, Suprematism, Futurism, Naïve Art, Gothic, Mannerism, Tonalism, Divisionism, Ashcan School, Precisionism, Social Realism, Neo-Impressionism, Kinetic Art, Lyrical Abstraction, Op Art, Hard-edge Painting, Color Field Painting, Conceptual Art, Land Art, New Objectivity, Orphism, Primitivism, Regionalism, Hyperrealism, Performance Art, Installation Art, Art Deco, Chromogenic Abstraction, Lowbrow Art, Digital Art, Environmental Art, Dada, Photorealism, Street Art, New Media Art.
        2. Artists: Leonardo da Vinci, Vincent van Gogh, Pablo Picasso, Michelangelo, Claude Monet, Salvador Dali, Frida Kahlo, Rembrandt van Rijn, Georgia O'Keeffe, Henri Matisse, Gustav Klimt, Wassily Kandinsky, Andy Warhol, Edvard Munch, Jackson Pollock, Pierre-Auguste Renoir, Diego Rivera, Henri Rousseau, Paul Cézanne, Paul Gauguin, Goya, Marc Chagall, Johannes Vermeer, Caravaggio, Edgar Degas, Raphael, Titian, Édouard Manet, Joan Miró, Henri de Toulouse-Lautrec, Diego Velázquez, Sandro Botticelli, Paul Klee, Grant Wood, Kazimir Malevich, Fernando Botero, Camille Pissarro, Amedeo Modigliani, Banksy, Norman Rockwell, Roy Lichtenstein, Peter Paul Rubens, Giotto di Bondone, Francisco Goya, Jan van Eyck, J.M.W. Turner, Édouard Vuillard, Francis Bacon, Katsushika Hokusai, Georges Seurat, Diego Giacometti, Giorgione, Gustave Courbet, M.C. Escher, Pieter Bruegel the Elder, Yayoi Kusama, Hans Holbein the Younger, Hans Memling, Marcel Duchamp, Robert Rauschenberg, Max Ernst, Utagawa Hiroshige, Kazuo Shiraga, Jenny Saville, Lucian Freud, Gustave Caillebotte, Albrecht Dürer, Klimt, Francisco de Zurbarán, Mary Cassatt, John Singer Sargent, Jean-Baptiste-Siméon Chardin, Paul Signac, Gustave Moreau, Amrita Sher-Gil, William-Adolphe Bouguereau, Alberto Giacometti, Michelangelo Merisi da Caravaggio, Willem de Kooning, El Greco, Francisco de Goya, Jasper Johns, Giuseppe Arcimboldo, Yves Klein, Edward Hopper, Mark Rothko, Jean-Michel Basquiat, Piet Mondrian, Claude Lorrain, Helen Frankenthaler, Artemisia Gentileschi, Anish Kapoor, Canaletto, David Hockney, Alfred Sisley, Élisabeth Vigée Le Brun, Joan Mitchell, Käthe Kollwitz, René Magritte, Tamara de Lempicka, Paula Modersohn-Becker, Rembrandt, Tintoretto, Édgar Degas, Hieronymus Bosch, Salvador Dalí, Józef Chełmoński, Stanisław Wyspiański, Olga Boznańska, Zdzisław Beksiński, Jerzy Duda-Gracz, Wojciech Weiss, Andrzej Wróblewski, Witold Wojtkiewicz, Leon Wyczółkowski, Julian Fałat, Jacek Malczewski, Jan Matejko, Tadeusz Makowski, Aleksander Gierymski, Artur Grottger, Jerzy Nowosielski, Henryk Siemiradzki, Roman Opałka, Władysław Strzemiński, Bruno Schulz, Magdalena Abakanowicz, Bogdan Achimescu, Władysław Hasior, Jerzy Tchórzewski, Rafał Olbiński, Henryk Stażewski, Józef Mehoffer, Wojciech Fangor, Leon Tarasewicz, Jerzy Panek, Roman Modzelewski, Ryszard Winiarski, Mieczysław Porębski, Tadeusz Kantor, Zbigniew Makowski, Jan Lebenstein, Edward Dwurnik, Andrzej Pawłowski, Jan Cybis, Anna Bilińska-Bohdanowicz, Aleksander Kobzdej, Lech Majewski, Józef Pankiewicz, Wojciech Siudmak, Juliusz Kossak, Zygmunt Ajdukiewicz, Johann Heinrich von Dannecker.
    5. Show only following elements:
        1. Long Description: Suggest expanded short description. Vividly depicting a realistic, detailed and intriguing depiction of the artistic fusion of style and painter artist. The description begins with text reflecting the elements described by the user and ends with information about the selected style and artist. The style and artist are not selected based on the elements described by the user. The long one should be integral and maintain stylistic and grammatical correctness as one paragraph. 
    6. Do not use title in descriptions. Start descriptions for example 'create', 'generate', 'bring', 'produce', 'paint', 'craft', 'design'.
"@

        Write-Verbose "Checking if prompt is provided"
        if (-not $prompt) {
            $prompt = read-Host "Prompt"
        }
        
        Write-Verbose "Calling the Invoke-PSAOAIChatCompletion function and removing unnecessary output"
        try {
            $chatOutput = Invoke-PSAOAIChatCompletion -User $User -OneTimeUserPrompt -usermessage $prompt -SystemPrompt $systemPrompt -Mode Creative -simpleresponse
            $chatOutput = $chatOutput.replace("Long Description: ", "")
            $chatOutput = $chatOutput.replace("Response assistant (assistant):", "")
            $chatOutput = $chatOutput.replace("`n", " ")
            $chatOutput = $chatOutput.TRIM()
        }
        catch {
            Write-Host "Error in Invoke-PSAOAIChatCompletion: $_" -ForegroundColor Red
            return
        }


        Write-Verbose "Checking if there's output from the chat completion"
        if ($chatOutput) {
            Write-Verbose "Displaying the chat output"
            Write-Host $chatOutput -ForegroundColor Cyan
            
            $promptaddstring = ""
            $dallePrompt = $chatOutput + $promptaddstring

            Write-Verbose "Checking if the AzureOpenAIImageGenerate switch is set"
            if ($AzureOpenAIImageGenerate) {

                Write-Verbose "Invoking other Azure OpenAI functions based on the chat output"
                try {
                    Invoke-PSAOAIDalle3 -prompt $dallePrompt -ImageLoops $ImageLoops -user $user -size $size
                }
                catch {
                    Write-Host "Error in Invoke-AzureOpenAIDALLE3: $_" -ForegroundColor Red
                }
            }
            Write-Verbose "Extracting width and height from size"
            $dimensions = $size.Split('x')
            $width = $dimensions[0]
            $height = $dimensions[1]

            Write-Verbose "Checking if the pollinations switch is set"
            if ($pollinations) {
                Write-Verbose "Generating artwork based on the chat output"
                try {
                    if ($model) {
                        Generate-Artwork -model $model -Prompt $chatOutput -Once -ImageLoops $ImageLoops -seed $seed -negative $negative -width $width -height $height
                    }
                    else {
                        Generate-Artwork -Prompt $chatOutput -Once -ImageLoops $ImageLoops -seed $seed -negative $negative -width $width -height $height
                    }
                    
                }
                catch {
                    Write-Host "Error in Generate-Artwork: $_" -ForegroundColor Red
                }
            }
        }
        else {
            Write-Verbose "Skipping further processing as there's no chat output"
            Write-Host "skipping..." -ForegroundColor DarkRed
        }

        Write-Verbose "Checking if the pollinationspaint switch is set"
        if ($pollinationspaint) {
            Write-Verbose "Generating artwork based on the initial prompt"
            try {
                if ($model) {
                    Generate-ArtworkPaint -model $model -Prompt $prompt -Once -ImageLoops $ImageLoops -seed $seed -negative $negative -width $width -height $height 
                }
                else {
                    Generate-ArtworkPaint -Prompt $prompt -Once -ImageLoops $ImageLoops -seed $seed -negative $negative -width $width -height $height
                }
            }
            catch {
                Write-Host "Error in Generate-ArtworkPaint: $_" -ForegroundColor Red
            }
        }
        Remove-Variable -Name prompt, chatOutput -ErrorAction SilentlyContinue
    }

    # The 'end' block is executed after all the input has been processed
    end {
        # Write a verbose message indicating the end time of the script and the total execution time calculation
        Write-Verbose "Recording the end time of the script and calculating the total execution time"
        
        # Get the current date and time and assign it to the 'endTime' variable
        $endTime = Get-Date
        
        # Calculate the total execution time by subtracting the start time from the end time and convert it to seconds
        $executionTime = ($endTime - $startTime).TotalSeconds
        
        # Display the total execution time in seconds
        Write-Host "Execution time: $executionTime seconds" -ForegroundColor Yellow

        # Remove the variables 'startTime', 'endTime', and 'executionTime' to free up memory, suppress any errors
        Remove-Variable -Name startTime, endTime, executionTime -ErrorAction SilentlyContinue
    }
}