# IntellectHub

IntellectHub is a project that leverages the power of AZURE OpenAI with PowerShell to conduct different tasks.

## Getting Started

To get started with IntellectHub, you need first to install PowerShell modules:
    - `PSAOAI`
    - `PSWriteColor`

After downloading, import the choosen project file or clone repo. Scripts in portfolio:
    - [IH](IH.ps1)
    - [PowerShellTeam](PowerShellTeam.ps1)
    - [OpenDomainDiscussion](OpenDomainDiscussion.ps1)
    - [DynamicExpertDiscussion](DynamicExpertDiscussion.ps1)
    - [OpenDomainDiscussion2_C](OpenDomainDiscussion2_C.ps1)
    - [OpenDomainDiscussion_CC](OpenDomainDiscussion_CC.ps1)

## Running the Script `OpenDomainDiscussion_CC.ps1`

The script for conducting the discussion is `OpenDomainDiscussion_CC.ps1`. This script conducts the discussion with a specified number of rounds and experts.

```powershell
# Conduct the discussion with 3 rounds and 2 experts. Streaming response HTTP.
.\OpenDomainDiscussion_CC.ps1 -Topic "suggest guide for python learning" -Rounds 3 -Stream $true
```

### A Team Discussion Folder

The script additionally generates a team discussion folder, which serves as a repository for all the data produced during the discussion. This folder is uniquely named with the current date and time. The root and default folder, named `OpenDomainDiscussion`, is located within the user's Document directory.

## Contributing

Contributions are welcome. Please feel free to fork the project and submit your pull requests.

## License

This project is licensed under the MIT License.
