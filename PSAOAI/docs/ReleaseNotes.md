# PowerShell Azure OpenAI (PSAOAI) - release notes

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

## [unreleased]

### Added

- 

### Fix

- Minor fixes.

### Changed

- Chat: Enhanced mode,
- Chat: Simplified environment variable handling,
- Refactoring.

## [0.3.0] - 2024.06.19

### Added

- Timeout param,
- Chat: param `max_tokens`.

## [0.2.1] - 2024.06.03

### Fix

- Chat: error returned as response,
- Chat: response.

### Changed

- Set default stream to TRUE,
- Chat: verification of response when not stream.

## [0.2.0] - 2024.05.30

### Added

- Logfolder parameter to Completion - [#3](https://github.com/voytas75/AzureOpenAI-PowerShell/issues/3),
- Completion: Added timestamp to log filename,
- Completion, Chat: Streaming response,
- Ready for core edition,
- Streaming response: timeout.

### Fix

- Completion, Chat: logfileDirectory.

### Changed

- Chat: logfilename suffix - [#4](https://github.com/voytas75/AzureOpenAI-PowerShell/issues/4)

## [0.1.0] - 2024.04.26

### Added

- Posiotional parameters,
- [#1](https://github.com/voytas75/AzureOpenAI-PowerShell/issues/1),
- Error handling: [#2](https://github.com/voytas75/AzureOpenAI-PowerShell/issues/2).

### Fix

- Passing temperature, topp, and mode parameters.

## [0.0.2] - 2024.04.17

### Added

- Function to retrieve the API versions from the Azure OpenAI GitHub repository.
- Function to clear the Azure OpenAI API environment variables.

### Changed

- Modified API key handling with security.
- Make functions as stand-alone files.

### Fix

- Secure API KEY.

## [0.0.1] - 2024.04.07

### Added

- Initiated the module for the first time.
