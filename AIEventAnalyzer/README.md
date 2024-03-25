# Start-AIEventAnalyzer

This PowerShell script, `Start-AIEventAnalyzer.ps1`, is designed to analyze Windows event logs using AI. It prompts the user to select an action, a log to analyze, the severity level of the events, and the number of most recent events to analyze. The script then invokes an AI model to analyze the selected events and logs the results.

## Syntax

```powershell
.\Start-AIEventAnalyzer.ps1
```

## Parameters

The script does not take any parameters. Instead, it prompts the user for the following inputs:

- **Action**: The type of analysis to perform. Options include "Analyze", "Troubleshoot", "Correlate", "Predict", "Optimize", "Audit", "Automate", "Educate", "Documentation", "Summarize".
- **LogName**: The name of the Windows event log to analyze.
- **Severity Level**: The severity level of the events to analyze. Options include "Critical", "Error", "Warning", "Information", "Verbose", "All".
- **Number of Events**: The number of most recent events to analyze.

## Example

```powershell
PS C:\> .\Start-AIEventAnalyzer.ps1
```

The script will then prompt the user for the required inputs.

## Output

The script outputs the results of the AI analysis to a text file in the `LogFolder` directory.  The file name is in the format `Action-LogName-SeverityLevel-DateTime.txt`.

- **LogFolder** (Optional): Specifies the directory where the output log files will be stored. If not provided, the script will create and use a directory named "AIEventAnalyzer" in the user's "MyDocuments" folder.

The output file contains the following information:

- The chosen action, log name, severity level, and event count.
- The prompt used for the AI analysis.
- The results of the AI analysis in JSON format.

The script also displays the chosen action, log name, severity level, and event count in the console.

![image](.\images\AiEventAnalyzer.gif)