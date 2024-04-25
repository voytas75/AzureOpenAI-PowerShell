# Load configuration from JSON file
function LoadConfigurationFromFile {
    param([string] $filePath)

    # Read configuration from file
    $configData = Get-Content -Path $filePath -Raw | ConvertFrom-Json

    # Parse entity data
    $entities = @()
    foreach ($entityData in $configData.Entities) {
        $entity = [Entity]::new($entityData.Name, $entityData.Role, $entityData.Description, $entityData.Skills, $entityData.GPTModel)
        $entities += $entity
    }

    return $entities
}

function Extract-PowershellCodeBlocks {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TextContent,
        [Parameter(Mandatory = $false)]
        [string]$Folder = "$([Environment]::GetFolderPath('MyDocuments'))\IH"
    )

    # Check if the folder exists, if not, create it
    if (!(Test-Path -Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder | Out-Null
    }

    # Define the regex pattern
    $pattern = '(?s)(?<=)```powershell\n([\s\S]*?)```\n'

    # Get all matches and iterate through them
    $matches = [regex]::Matches($TextContent, $pattern)
    foreach ($match in $matches) {

        # Get the captured text from the group
        $code = $match.Groups[1].Value

        if (![string]::IsNullOrEmpty($code)) {

            # Save the code to a file, using a unique name
            $fileName = "code" + [System.Guid]::NewGuid().ToString() + ".ps1"
            $filePath = Join-Path -Path $Folder -ChildPath $fileName
            $code | Out-File -FilePath $filePath -Encoding UTF8
            # Print a message to indicate successful extraction
            Write-Host "Code block extracted and saved to $filePath"
        }

    }
}

function Create-FolderInUserDocuments {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderName
    )

    # Get the path to the user's Documents folder
    $UserDocumentsPath = [Environment]::GetFolderPath('MyDocuments')

    # Combine the Documents path with the folder name to get the full path
    $FolderPath = Join-Path -Path $UserDocumentsPath -ChildPath $FolderName

    # Check if the folder exists, if not, create it
    if (!(Test-Path -Path $FolderPath)) {
        New-Item -ItemType Directory -Path $FolderPath | Out-Null
    }

    # Return the full path of the folder
    return $FolderPath
}
function Create-FolderInGivenPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,
        [Parameter(Mandatory = $true)]
        [string]$FolderName
    )

    # Combine the Folder path with the folder name to get the full path
    $FullFolderPath = Join-Path -Path $FolderPath -ChildPath $FolderName

    # Check if the folder exists, if not, create it
    if (!(Test-Path -Path $FullFolderPath)) {
        New-Item -ItemType Directory -Path $FullFolderPath | Out-Null
    }

    # Return the full path of the folder
    return $FullFolderPath
}

function Save-DiscussionResponse {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TextContent,
        [Parameter(Mandatory = $false)]
        [string]$Folder = "$([Environment]::GetFolderPath('MyDocuments'))\IH"
    )

    # Check if the folder exists, if not, create it
    if (!(Test-Path -Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder | Out-Null
    }

    # Save the discussion response to a file, using a unique name
    $fileName = "discussionResponse" + [System.Guid]::NewGuid().ToString() + ".txt"
    $filePath = Join-Path -Path $Folder -ChildPath $fileName
    $TextContent | Out-File -FilePath $filePath -Encoding UTF8

    # Print a message to indicate successful saving
    Write-Host "Discussion response saved to $fileName"

    # Return the full path of the file
    return $filePath
}
function ReadDiscussionStepsFromJson {
    param(
        [string] $FilePath
    )

    # Read JSON data from file
    $jsonData = Get-Content -Path $FilePath -Raw | ConvertFrom-Json

    # Return the discussion steps
    return $jsonData.DiscussionSteps
}

function Get-ExpertsFromJson {
    param(
        [string] $FilePath = "experts.json"
    )

    # Check if the file exists
    if (!(Test-Path -Path $FilePath)) {
        Write-Error "File $FilePath does not exist."
        return $null
    }

    # Read JSON data from file
    $jsonData = Get-Content -Path $FilePath -Raw | ConvertFrom-Json

    # Return the experts
    return $jsonData
}
