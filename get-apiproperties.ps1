param (
    [Parameter()]
    $RawAPIUrl
)

$response=Invoke-RestMethod -Uri $RawAPIUrl -TimeoutSec 5

# chat completions
Write-Output "chat completions, properties"
# properties
$response.paths."/deployments/{deployment-id}/chat/completions".post.requestBody.content."application/json".schema.properties
Write-Output "chat completions, required"
#required
$response.paths."/deployments/{deployment-id}/chat/completions".post.requestBody.content."application/json".schema.required

# completions
Write-Output "completions, properties"
$response.paths."/deployments/{deployment-id}/completions".post.requestBody.content."application/json".schema.properties
#required
Write-Output "completions, required"
$response.paths."/deployments/{deployment-id}/completions".post.requestBody.content."application/json".schema.required

# embeddings
Write-Output "embeddings, properties"
$response.paths."/deployments/{deployment-id}/embeddings".post.requestBody.content."application/json".schema.properties
#required
Write-Output "embeddings, required"
$response.paths."/deployments/{deployment-id}/embeddings".post.requestBody.content."application/json".schema.required