
# Define the name of the current module
$ModuleName = "PSAOAI"
$ModuleNameFull = "PowerShell Azure OpenAI"

# Get all public and private PowerShell scripts in the module
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue -Recurse )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue -Recurse )

# Check if the PowerShell edition is core, if so, exit the script
if ($PSEdition -eq 'core') {
    Write-Error "Module can not be run on core edition!"
    exit
}

# Import all the public and private scripts, and catch any errors
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

# If there are any errors, warn the user and stop the script
if ($FoundErrors.Count -gt 0) {
    $ModuleName = (Get-ChildItem $PSScriptRoot\*.psd1).BaseName
    Write-Warning "Importing module $ModuleName failed. Fix errors before continuing."
    break
}

# Set the security protocol to TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Get the installed version of the module
$ModuleVersion = [version]"0.0.1"

# Check the PSGallery repository for the latest version of the module
$LatestModule = Find-Module -Name $ModuleName -Repository PSGallery -ErrorAction SilentlyContinue

# If a newer version is available, notify the user
try {
    if ($ModuleVersion -lt $LatestModule.Version) {
        Write-Host "An update is available for $($ModuleName). Installed version: $($ModuleVersion). Latest version: $($LatestModule.Version)." -ForegroundColor Red
    } 
}
catch {
    Write-Error "An error occurred while checking for updates: $_"
}

# Welcome the user to the module
Write-Host "Welcome to $ModuleNameFull ($ModuleName)!" -ForegroundColor DarkYellow
Write-Host "Thank you for using $ModuleNameFull ($($moduleVersion))" -ForegroundColor Yellow
