<#
.SYNOPSIS
    Extracts PowerShell code blocks from a given text string and writes them to a specified file with customizable delimiters.

.DESCRIPTION
    This script identifies and extracts PowerShell code blocks from a provided text string based on custom delimiters. Each extracted block is cleaned and written to a specified output file. It handles large inputs by processing them in chunks.

.PARAMETER InputString
    The string from which PowerShell code blocks will be extracted.

.PARAMETER OutputFilePath
    The file path where the extracted code blocks will be written.

.PARAMETER StartDelimiter
    The starting delimiter for a PowerShell code block. Default is '```powershell'.

.PARAMETER EndDelimiter
    The ending delimiter for a PowerShell code block. Default is '```'.

.EXAMPLE
    .\Extract-PowerShellCodeBlocks.ps1 -InputString $inputText -OutputFilePath "C:\output\extractedCodeBlocks.txt" -StartDelimiter '```ps' -EndDelimiter '```'
    Extracts PowerShell code blocks from $inputText using custom delimiters and writes them to "C:\output\extractedCodeBlocks.txt".
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$InputString,

    [Parameter(Mandatory = $true)]
    [string]$OutputFilePath,

    [string]$StartDelimiter = '```powershell',
    [string]$EndDelimiter = '```'
)

function Extract-AndWrite-PowerShellCodeBlocks {
    param(
        [string]$InputString,
        [string]$OutputFilePath,
        [string]$StartDelimiter,
        [string]$EndDelimiter
    )

    # Define the regular expression pattern to match PowerShell code blocks
    $pattern = '(?s)' + [regex]::Escape($StartDelimiter) + '(.*?)' + [regex]::Escape($EndDelimiter)

    try {
        # Handle large inputs by processing in chunks
        $bufferSize = 4096
        $stringReader = New-Object System.IO.StringReader($InputString)
        $buffer = New-Object char[] $bufferSize
        $tempOutput = ""
        while (($readLen = $stringReader.Read($buffer, 0, $buffer.Length)) -ne 0) {
            $tempOutput += [string]::new($buffer, 0, $readLen)
            # Process each complete block found within chunks
            if ($tempOutput -match $pattern) {
                $matches_ = [regex]::Matches($tempOutput, $pattern)
                foreach ($match in $matches_) {
                    $codeBlock = $match.Groups[1].Value.Trim()
                    $codeBlock | Out-File -FilePath $OutputFilePath -Append -Encoding UTF8
                    Write-Output "Code block written to file: $OutputFilePath"
                }
                # Reset temporary output to handle remaining incomplete blocks
                $tempOutput = $tempOutput.SubString($tempOutput.LastIndexOf($EndDelimiter) + $EndDelimiter.Length)
            }
        }
    }
    catch {
        Write-Error "An error occurred while processing: $_"
    }
    finally {
        $stringReader.Dispose()
    }
}

# Invoke the function with provided parameters
Extract-AndWrite-PowerShellCodeBlocks -InputString $InputString -OutputFilePath $OutputFilePath -StartDelimiter $StartDelimiter -EndDelimiter $EndDelimiter