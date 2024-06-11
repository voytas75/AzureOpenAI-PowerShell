# AIPSTeam.ps1 - Simulating Teamwork in PowerShell Scripting

[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/AIPSTeam)](https://www.powershellgallery.com/packages/AIPSTeam)

## Overview

This script (powered by [PSAOAI Module](https://github.com/voytas75/AzureOpenAI-PowerShell/tree/master/PSAOAI)) simulates a collaborative environment where specialists work together on a project, mimicking a real-world team dynamic within a single script. User input outlining the project details is passed through a chain of specialists, each performing their designated task and forwarding the information to the next specialist until the project is complete.

## Key Features

* **Specialist Roles:** The script emulates specialists like a Project Manager, a Documentator, and potentially others depending on your implementation.
* **User Input Driven:** The user defines the project scope through the `userInput` parameter.
* **Streaming Control:** The `Stream` parameter enables control over live output streaming during the project execution.
* **Optional Disabling:** You can selectively disable specific specialist functionalities using the `NOPM`, `NODocumentator`, and `NOLog` parameters.
* **Customizable Logging:** The `LogFolder` parameter allows defining a location for storing project logs.

## Parameters

* `userInput (string)`: Defines the project outline. (Default: RAM load monitoring and color block output based on load)
* `Stream (bool)`: Controls live output streaming. (Default: $true)
* `NOPM (switch)`: Disables Project Manager project summary functionality.
* `NODocumentator (switch)`: Disables Documentator functionality.
* `NOLog (switch)`: Disables logging functionality.
* `LogFolder (string)`: Specifies the folder for logs.

## Inputs

The script doesn't accept piped objects. All input comes through the defined parameters.

## Outputs

Output varies based on specialist actions. It typically includes text messages, status updates, or visual representations (e.g., graphs) depending on the user input.

## Example

```powershell
.\AIPSTeam.ps1 -userInput "A PowerShell project to monitor CPU usage and display dynamic graph." -Stream $false
```

This example runs the script with disabled live streaming (`-Stream $false`) and defines a project for CPU usage monitoring with a dynamic graph instead of the default RAM load and color block output.

