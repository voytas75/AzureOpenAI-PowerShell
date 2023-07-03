# Function Name: Invoke-APICall

## Description
This function sends an HTTP request to an API endpoint and retrieves the response using the Invoke-RestMethod cmdlet in PowerShell.

## Syntax
```powershell
Invoke-APICall -RawAPIUrl <string>
```

## Parameters
- `-RawAPIUrl` (Required): Specifies the URL of the API endpoint to make the request to.

## Example
```powershell
$response = Invoke-APICall -RawAPIUrl "https://api.example.com/endpoint"
```

## Output
The function retrieves the response from the API endpoint and assigns it to the `$response` variable.

### Chat Completions
#### Properties
```powershell
$response.paths."/deployments/{deployment-id}/chat/completions".post.requestBody.content."application/json".schema.properties
```
#### Required
```powershell
$response.paths."/deployments/{deployment-id}/chat/completions".post.requestBody.content."application/json".schema.required
```

### Completions
#### Properties
```powershell
$response.paths."/deployments/{deployment-id}/completions".post.requestBody.content."application/json".schema.properties
```
#### Required
```powershell
$response.paths."/deployments/{deployment-id}/completions".post.requestBody.content."application/json".schema.required
```

### Embeddings
#### Properties
```powershell
$response.paths."/deployments/{deployment-id}/embeddings".post.requestBody.content."application/json".schema.properties
```
#### Required
```powershell
$response.paths."/deployments/{deployment-id}/embeddings".post.requestBody.content."application/json".schema.required
```