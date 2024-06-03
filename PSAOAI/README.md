# PowerShell Azure OpenAI (PSAOAI) Module

![PSAOAI](https://raw.githubusercontent.com/voytas75/AzureOpenAI-PowerShell/master/images/PSAOAI128.png "PowerShell Azure OpenAI (PSAOAI) Module")


[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/A0A6KYBUS)

[![status](https://img.shields.io/badge/PROD-v0.2.1-green)](https://github.com/voytas75/AzureOpenAI-PowerShell/blob/master/PSAOAI/docs/ReleaseNotes.md) &nbsp; [![status](https://img.shields.io/badge/DEV-v0.2.2-red)](https://github.com/voytas75/AzureOpenAI-PowerShell/blob/master/PSAOAI/docs/ReleaseNotes.md) &nbsp; ![PowerShell version](https://img.shields.io/badge/PowerShell-v5.1-blue) &nbsp; ![PowerShell version](https://img.shields.io/badge/PowerShell-v7-darkblue) &nbsp; [![PowerShell Gallery Version (including pre-releases)](https://img.shields.io/powershellgallery/v/PSAOAI)](https://www.powershellgallery.com/packages/PSAOAI) &nbsp; [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PSAOAI)](https://www.powershellgallery.com/packages/PSAOAI)

## Overview

The PSAOAI (PowerShell Azure OpenAI) module is a powerful tool designed to interact with Azure OpenAI Services. It leverages the Azure OpenAI API to provide a seamless and efficient way to manage and utilize Azure OpenAI Services directly from your PowerShell environment.

This module allows you to perform a variety of tasks such as managing, and interacting with OpenAI models, generating text, images, and analyzing the output. It is designed to be user-friendly and efficient, making it easy for both beginners and experienced users to leverage the power of Azure OpenAI Services.

Whether you're looking to automate tasks, generate insightful data, or simply explore the capabilities of Azure OpenAI, the PSAOAI module is a valuable addition to your PowerShell toolkit.

![PSAOAI](https://raw.githubusercontent.com/voytas75/AzureOpenAI-PowerShell/master/images/PSAOAI.png "PowerShell Azure OpenAI (PSAOAI) Module")

## PSAOAI module features

- (Chat) Completion
- Embedding
- Generate Image (DALL-E 3)
- Secure API KEY
- Log responses

## Installation

The module is available on [PowerShell Gallery](https://www.powershellgallery.com/packages/PowerShellAZUREOpenAI).

```powershell
Install-Module -Name PSAOAI
```

Import module:

```powershell
Import-Module -Module PSAOAI
```

To get all commands in installed module including cmdlets, functions and aliases:

```powershell
Get-Command -Module PSAOAI
```

## Usage

### Chat Completion

```powershell
"AZURE Logic App 'IF' element" | Invoke-PSAOAIChatCompletion -APIVersion "2023-06-01-preview" -Endpoint 
"https://example.openai.azure.com" -Deployment "example_model_gpt35_!" -User "BobbyK" -Temperature 0.3 -TopP 1 
-FrequencyPenalty 0 -PresencePenalty 0 -simpleresponse -SystemPrompt "Explain to me" -Stream $false
```

### Completion

```powershell
Invoke-PSAOAIcompletion -usermessage "explain winform" -Deployment "35TURBO" -User "BobbyK" -simpleresponse -Stream $false
```

### Generation image

```powershell
Invoke-PSAOAIDalle3 -Prompt "A finely detailed, broken marble figure head half-submerged in sandy terrain. The scene is 
bathed in the illuminating glow of daylight. The artistic style of the image evokes the feel of Polish romanticism, 
characterized by a realistic approach with an underlying emotional dimension and emphasis on symbolic compositions often seen 
in Malczewski's works who was active before 1912. Please note, the marble figure head should be of no particular person, just 
a generic, anonymous sculpture." -quality hd 
```

### Embeddings

```powershell
$response = "Hello, World!" | Invoke-PSAOAIEmbedding -User "Gemini" -Verbose -Deployment "gpt-7" -simpleresponse
$response
```

## Default Log and Data Folder

The PSAOAI module uses default folder for storing log files and data. If specific paths are not provided, the module uses `<User's document folder>/PSAOAI/` folder.

*INFO*: In the PSAOAI PowerShell module, the default location for the log and data folder is the user's document folder. If the log and data folder does not exist, it will be created automatically when the module is imported.

## Versioning

We use [SemVer](http://semver.org/) for versioning.

## Contributing

We welcome contributions from the community! Feel free to submit pull requests, report issues, or suggest new features to make the framework even more powerful and user-friendly.

**Clone the Repository:** Clone the PSAOAI repository to your local machine.

### License

The PSAOAI is released under the [MIT License](https://github.com/voytas75/AzureOpenAI-PowerShell/blob/master/PSAOAI/LICENSE).

**Contact:**
If you have any questions or need assistance, please feel free to reach out to us via [GitHub Issues](https://github.com/voytas75/AzureOpenAI-PowerShell/issues).

Join us on the journey to make PowerShell scripting a truly awesome experience!
