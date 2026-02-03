param(
    [Parameter(Mandatory=$true)][string]$AuthToken,
    [Parameter(Mandatory=$true)][string]$FilePath,
    [Parameter(Mandatory=$true)][string]$ArtifactUUID
)

try {
    $resolved = Resolve-Path -Path $FilePath -ErrorAction Stop
    $FilePath = $resolved.Path
} catch {
    Write-Error "File not found: $FilePath"
    exit 1
}

$FileName = Split-Path -Path $FilePath -Leaf
$FileSize = (Get-Item -LiteralPath $FilePath).Length

$baseUrl = "https://api.bitrise.io/release-management/v1/connected-apps/c0ad8c8f-f85a-4566-b1cf-407b74666ede/installable-artifacts/$ArtifactUUID"
$request1 = "$baseUrl/upload-url?file_name=$([System.Uri]::EscapeDataString($FileName))&file_size_bytes=$FileSize"

$headers = @{ Authorization = $AuthToken }

Write-Host "Requesting upload URL..."
try {
    $response1 = Invoke-RestMethod -Uri $request1 -Headers $headers -Method Get -ErrorAction Stop
} catch {
    Write-Error "Failed to get upload URL: $($_.Exception.Message)"
    exit 1
}

# Try common JSON paths for upload URL
$uploadUrl = $null
if ($response1 -is [System.Collections.IDictionary]) {
    if ($response1.ContainsKey('upload_url')) { $uploadUrl = $response1.upload_url }
    elseif ($response1.ContainsKey('uploadURL')) { $uploadUrl = $response1.uploadURL }
    elseif ($response1.ContainsKey('data') -and $response1.data -is [System.Collections.IDictionary] -and $response1.data.ContainsKey('upload_url')) { $uploadUrl = $response1.data.upload_url }
}

if (-not $uploadUrl) {
    Write-Error "Upload URL not found in response. Response dump:" 
    $response1 | ConvertTo-Json -Depth 5
    exit 1
}

Write-Host "Uploading file to pre-signed URL..."
$putHeaders = @{
    "Content-Type" = "application/octet-stream"
    "X-Goog-Content-Length-Range" = "0,$FileSize"
}
try {
    Invoke-RestMethod -Uri $uploadUrl -Method Put -InFile $FilePath -Headers $putHeaders -ContentType "application/octet-stream" -ErrorAction Stop
    Write-Host "Upload finished."
} catch {
    Write-Error "Upload failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "Checking status..."
$request3 = "$baseUrl/status"
try {
    $response3 = Invoke-RestMethod -Uri $request3 -Headers $headers -Method Get -ErrorAction Stop
    $response3 | ConvertTo-Json -Depth 5
} catch {
    Write-Error "Failed to get status: $($_.Exception.Message)"
    exit 1
}

Write-Host "Done."