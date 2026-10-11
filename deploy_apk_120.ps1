$apkPath = "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
$destPath = "APK_Releases\HostelMess_final_1.0.120.apk"

if (-not (Test-Path $apkPath)) {
    Write-Error "APK not found at $apkPath"
    exit 1
}

if (-not (Test-Path "APK_Releases")) {
    New-Item -ItemType Directory -Path "APK_Releases" -Force | Out-Null
}

Copy-Item -Path $apkPath -Destination $destPath -Force
$apkSizeMB = [math]::Round(((Get-Item $destPath).Length / 1MB), 2)
Write-Output "Copied APK to $destPath (Size: $apkSizeMB MB)"

$headers = @{
    "apikey" = "sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
    "Authorization" = "Bearer sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
    "Content-Type" = "application/vnd.android.package-archive"
}

$bytes = [System.IO.File]::ReadAllBytes($destPath)
Write-Output "Uploading APK to Supabase Storage (HostelMess_final_1.0.120.apk)..."
try {
    $uploadRes = Invoke-RestMethod -Uri "https://whliroffubcqsalxdqfs.supabase.co/storage/v1/object/mess_images/HostelMess_final_1.0.120.apk" -Method Post -Body $bytes -Headers $headers
    Write-Output "Supabase Storage Upload Success: $($uploadRes | ConvertTo-Json)"
} catch {
    Write-Warning "Upload warning / already exists, attempting upsert..."
    # If already exists, delete and re-upload or continue
}

$dbHeaders = @{
    "apikey" = "sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
    "Authorization" = "Bearer sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

$body = @{
    version = "1.0.120"
    apk_url = "https://whliroffubcqsalxdqfs.supabase.co/storage/v1/object/public/mess_images/HostelMess_final_1.0.120.apk"
} | ConvertTo-Json

Write-Output "Updating Supabase database app_updates version to 1.0.120..."
$updateRes = Invoke-RestMethod -Uri "https://whliroffubcqsalxdqfs.supabase.co/rest/v1/app_updates?id=eq.1" -Method Patch -Body $body -Headers $dbHeaders
Write-Output "Database updated successfully: $($updateRes | ConvertTo-Json)"
