# IntellectHub

IntellectHub is a project that leverages the power of PowerShell to conduct open domain discussions. It uses a technique called "Mirror of Thoughts" to generate diverse and inclusive content.

## Getting Started

To get started with IntellectHub, you need to familiarize yourself with the Mirror of Thoughts technique. Understand its methodology, principles, and anticipated outcomes. Gather the necessary materials, including prompts relevant to the session's topic.

## Running the Script

The main script for conducting the discussion is `OpenDomainDiscussion_CC.ps1`. This script conducts the discussion with a specified number of rounds and experts.

```powershell
# Conduct the discussion with 3 rounds and 5 experts
Conduct-Discussion -topic $topic -rounds $Rounds -expertCount $expertCount
```

## Creating a Team Discussion Folder

The script also creates a team discussion folder where all the discussion data is stored. The folder is created with the current date and time as the name in the example path.

```powershell
# Get the current date and time
$currentDateTime = Get-Date -Format "yyyyMMdd_HHmmss"
# Create a folder with the current date and time as the name in the example path
$script:TeamDiscussionDataFolder = Create-FolderInGivenPath -FolderPath $(Create-FolderInUserDocuments -FolderName "OpenDomainDiscussion") -FolderName $currentDateTime
```

## Contributing

Contributions are welcome. Please feel free to fork the project and submit your pull requests.

## License

This project is licensed under the MIT License.
