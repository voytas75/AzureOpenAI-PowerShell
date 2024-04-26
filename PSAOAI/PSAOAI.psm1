
# Set the current module's name
$script:ModuleName = "PSAOAI"
$script:ModuleNameFull = "PowerShell Azure OpenAI"

# Retrieve all public and private PowerShell scripts within the module
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue -Recurse )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue -Recurse )

# If the PowerShell edition is 'core', terminate the script
if ($PSEdition -eq 'core') {
    Write-Error "Module can not be run on core edition!"
    exit
}

# Import all public and private scripts, and handle any potential errors
$FoundErrors = @(
    Foreach ($Import in @($Public + $Private)) {
        Try {
            . $Import.Fullname
        }
        Catch {
            Write-Error -Message "Failed to import functions from $($import.Fullname): $_"
            $true
        }
    }
)

# If any errors are found, alert the user and halt the script
if ($FoundErrors.Count -gt 0) {
    $ModuleElementName = (Get-ChildItem $PSScriptRoot\*.psd1).BaseName
    Write-Warning "Importing module $ModuleElementName failed. Fix errors before continuing."
    break
}

# Enforce the use of TLS 1.2 security protocol
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Determine the installed version of the module
$ModuleVersion = [version]"0.1.0"

# Query the PSGallery repository for the most recent version of the module
$LatestModule = Find-Module -Name $script:ModuleName -Repository PSGallery -ErrorAction SilentlyContinue

# If a more recent version is available, inform the user
try {
    if ($ModuleVersion -lt $LatestModule.Version) {
        Write-Host "An update is available for $script:ModuleName. Installed version: $ModuleVersion. Latest version: $($LatestModule.Version)." -ForegroundColor Red
    } 
}
catch {
    Write-Error "An error occurred while checking for updates: $_"
}

# Set constants for environment variable names
$script:API_AZURE_OPENAI_APIVERSION = "PSAOAI_API_AZURE_OPENAI_APIVERSION"
$script:API_AZURE_OPENAI_ENDPOINT = "PSAOAI_API_AZURE_OPENAI_ENDPOINT"
$script:API_AZURE_OPENAI_CC_DEPLOYMENT = "PSAOAI_API_AZURE_OPENAI_CC_DEPLOYMENT" # Chat Completion
$script:API_AZURE_OPENAI_C_DEPLOYMENT = "PSAOAI_API_AZURE_OPENAI_C_DEPLOYMENT" # Completion
$script:API_AZURE_OPENAI_D3_DEPLOYMENT = "PSAOAI_API_AZURE_OPENAI_D3_DEPLOYMENT" # Dall-e 3
$script:API_AZURE_OPENAI_E_DEPLOYMENT = "PSAOAI_API_AZURE_OPENAI_E_DEPLOYMENT" # Embedding
$script:API_AZURE_OPENAI_KEY = "PSAOAI_API_AZURE_OPENAI_KEY"
$script:PSAOAI_BANNER = "PSAOAI_BANNER"

# Setting the environment variable for the API version
Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_APIVERSION -VariableValue $(get-apiversion -preview | select-object -first 1) -PromptMessage "API Version"
#write-host (Get-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_APIVERSION )
#Set-EnvironmentVariable -VariableName "PSAOAI_BANNER" -VariableValue "1"
if ( [string]::IsNullOrEmpty((Get-EnvironmentVariable -VariableName $script:PSAOAI_BANNER))) {
    Get-PSAOAIBanner

    # Greet the user upon module initiation
    Write-Host "Welcome to $script:ModuleNameFull ($script:ModuleName)!" -ForegroundColor Cyan
    Write-Host "Thank you for using $script:ModuleNameFull ($($moduleVersion))" -ForegroundColor DarkGreen
    write-Host ""
    write-Host "To disable the banner and welcome follow:" -ForegroundColor DarkGray
    write-Host '[System.Environment]::SetEnvironmentVariable("PSAOAI_BANNER", "0", "User")' -ForegroundColor DarkGray
    write-Host ""
}