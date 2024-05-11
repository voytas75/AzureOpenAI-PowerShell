# This function makes an API request and stores the response
function Invoke-PSAOAIApiRequest {
    <#
    .SYNOPSIS
    Sends a POST request to the specified API and stores the response.

    .DESCRIPTION
    The Invoke-ApiRequest function sends a POST request to the API specified by the url parameter. It uses the provided headers and bodyJSON for the request. 
    If the request is successful, it returns the response. If an error occurs during the request, it handles the error and returns null.

    .PARAMETER url
    Specifies the URL for the API request. This parameter is mandatory.

    .PARAMETER headers
    Specifies the headers for the API request. This parameter is mandatory.

    .PARAMETER bodyJSON
    Specifies the body for the API request. This parameter is mandatory.

    .EXAMPLE
    Invoke-ApiRequest -url $url -headers $headers -bodyJSON $bodyJSON

    .OUTPUTS
    If successful, it outputs the response from the API request. If an error occurs, it outputs null.
    #>    
    param(
        [Parameter(Mandatory = $true)]
        [string]$url, # The URL for the API request

        [Parameter(Mandatory = $true)]
        [hashtable]$headers, # The headers for the API request

        [Parameter(Mandatory = $true)]
        [string]$bodyJSON, # The body for the API request

        [Parameter(Mandatory = $false)]
        $timeout = 60
    )

    # Try to send the API request and handle any errors
    try {
        # Start a new job to send the API request
        $response = Start-Job -ScriptBlock {
            param($url, $headers, $bodyJSON, $timeout)
            # Send the API request
            Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $bodyJSON -TimeoutSec $timeout -ErrorAction Stop
        } -ArgumentList $url, $headers, $bodyJSON, $timeout
        
        # Write verbose output for the job
        Write-Verbose ("Job: $($response | ConvertTo-Json)" )

        # Wait for the job to finish
        while (($response.JobStateInfo.State -eq 'Running') -or ($response.JobStateInfo.State -eq 'NotStarted')) {
            Write-Host "." -NoNewline -ForegroundColor Blue
            Start-Sleep -Milliseconds 1000
        }
        Write-Host ""    

        # If the job failed, write the error message
        if ($response.JobStateInfo.State -eq 'Failed') {
            Write-Warning $($response.ChildJobs[0].JobStateInfo.Reason.message)

            return 
        }

        # Receive the job result
        $response = Receive-Job -Id $response.Id -Wait -ErrorAction Stop

        # Write verbose output for the response
        Write-Verbose ($response | Out-String)

        # Return the response
        return $response

        Write-Host ""
    }
    # Catch any errors and write a warning
    catch {
        Write-Warning ($_.Exception.Message)
    }
}
