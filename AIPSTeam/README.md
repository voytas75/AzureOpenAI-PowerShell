# AI PowerShell Team Script

[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/AIPSTeam)](https://www.powershellgallery.com/packages/AIPSTeam)

## Table of Contents

- [AI PowerShell Team Script](#ai-powershell-team-script)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Features](#features)
  - [User Guide](#user-guide)
    - [Installation](#installation)
    - [Configuration](#configuration)
    - [Usage](#usage)
  - [Developer Notes](#developer-notes)
    - [Code Structure](#code-structure)
    - [Key Functions and Logic](#key-functions-and-logic)
  - [Installation Instructions](#installation-instructions)
  - [Dependencies and Prerequisites](#dependencies-and-prerequisites)
  - [Use Cases and Expected Outputs](#use-cases-and-expected-outputs)
  - [Troubleshooting Tips and Common Issues](#troubleshooting-tips-and-common-issues)
  - [FAQ](#faq)

## Overview

This PowerShell script simulates a team of specialists working together on a PowerShell project. Each specialist has a unique role and contributes to the project in a sequential manner. The script processes user input, performs various tasks, and generates outputs such as code, documentation, and analysis reports.

## Features

- **Team Simulation**: Emulates a team of specialists including Requirements Analyst, System Architect, PowerShell Developer, QA Engineer, Documentation Specialist, and Project Manager.
- **Sequential Processing**: Each specialist processes the input and passes the result to the next specialist in the workflow.
- **Live Streaming**: Option to stream output live.
- **Logging**: Logs actions and responses of each specialist.
- **Documentation Generation**: Automatically generates comprehensive documentation for the project.
- **Code Analysis**: Integrates with PSScriptAnalyzer for code quality checks.
- **Interactive Menu**: Provides an interactive menu for suggesting new features, analyzing code, generating documentation, and more.

## User Guide

### Installation

1. **Download the Script**: Clone or download the repository from [GitHub](https://github.com/voytas75/AzureOpenAI-PowerShell/tree/master/AIPSTeam/README.md).
2. **Install Required Modules**: Ensure you have the required PowerShell modules installed:

   ```powershell
   Install-Module -Name PSAOAI
   Install-Module -Name PSScriptAnalyzer
   ```

3. **Run the Script**: Execute the script using PowerShell:

   ```powershell
   .\AIPSTeam.ps1 -userInput "Your project description here"
   ```

### Configuration

- **Parameters**:
  - `-userInput`: Defines the project outline as a string.
  - `-Stream`: Controls whether the output should be streamed live (default: `$true`).
  - `-NOPM`: Disables the Project Manager functions.
  - `-NODocumentator`: Disables the Documentator functions.
  - `-NOLog`: Disables the logging functions.
  - `-LogFolder`: Specifies the folder where logs should be stored.

### Usage

1. **Basic Usage**:

   ```powershell
   .\AIPSTeam.ps1 -userInput "Monitor RAM usage and show a single color block based on the load."
   ```

2. **Disable Live Streaming**:

   ```powershell
   .\AIPSTeam.ps1 -userInput "Monitor RAM usage" -Stream $false
   ```

3. **Specify Log Folder**:

   ```powershell
   .\AIPSTeam.ps1 -userInput "Monitor RAM usage" -LogFolder "C:\Logs"
   ```

## Developer Notes

### Code Structure

- **Main Script**: `AIPSTeam.ps1`
- **Classes**: `ProjectTeam`
- **Functions**: Various utility functions for processing input, logging, and analysis.

### Key Functions and Logic

- **ProjectTeam Class**: Represents a team member with specific expertise.
  - `ProcessInput`: Processes the input and generates a response.
  - `Feedback`: Provides feedback on the input.
  - `AddLogEntry`: Adds an entry to the log.
  - `Notify`: Sends a notification.
  - `SummarizeMemory`: Summarizes the team member's memory.
- **Utility Functions**:
  - `SendFeedbackRequest`: Sends a feedback request to a team member.
  - `Invoke-CodeWithPSScriptAnalyzer`: Analyzes the code using PSScriptAnalyzer.
  - `Export-AndWritePowerShellCodeBlocks`: Exports and writes PowerShell code blocks to a file.

## Installation Instructions

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/voytas75/AzureOpenAI-PowerShell.git
   ```

2. **Navigate to the Directory**:

   ```bash
   cd AzureOpenAI-PowerShell/AIPSTeam
   ```

3. **Install Required Modules**:

   ```powershell
   Install-Module -Name PSAOAI
   Install-Module -Name PSScriptAnalyzer
   ```

## Dependencies and Prerequisites

- **PowerShell Version**: Ensure you are using PowerShell 5.1 or later.
- **Modules**:
  - `PSAOAI`
  - `PSScriptAnalyzer`

## Use Cases and Expected Outputs

1. **Monitor RAM Usage**:

   ```powershell
   .\AIPSTeam.ps1 -userInput "Monitor RAM usage and show a single color block based on the load."
   ```

   **Expected Output**: A color block indicating RAM usage levels.

2. **Monitor CPU Usage**:

   ```powershell
   .\AIPSTeam.ps1 -userInput "Monitor CPU usage and display dynamic graph."
   ```

   **Expected Output**: A dynamic graph showing CPU usage.

## Troubleshooting Tips and Common Issues

- **Module Not Found**: Ensure the required modules are installed using `Install-Module`.
- **Permission Issues**: Run PowerShell as an administrator.
- **Script Errors**: Check the log files in the specified log folder for detailed error messages.

## FAQ

1. **How do I install the required modules?**

   ```powershell
   Install-Module -Name PSAOAI
   Install-Module -Name PSScriptAnalyzer
   ```

2. **How do I disable live streaming?**

   ```powershell
   .\AIPSTeam.ps1 -Stream $false
   ```

3. **Where are the log files stored?**

   Log files are stored in the specified log folder or the default folder in `MyDocuments`.
