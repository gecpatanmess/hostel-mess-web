$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
$destPath = "APK_Releases\HostelMess_final_1.0.76.apk"
Copy-Item -Path $apkPath -Destination $destPath -Force

$headers = @{
    "apikey" = "sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
    "Authorization" = "Bearer sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
    "Content-Type" = "application/vnd.android.package-archive"
}
$bytes = [System.IO.File]::ReadAllBytes($destPath)
Write-Output "Uploading APK to Supabase Storage..."
Invoke-RestMethod -Uri "https://whliroffubcqsalxdqfs.supabase.co/storage/v1/object/mess_images/HostelMess_final_1.0.76.apk" -Method Post -Body $bytes -Headers $headers

$dbHeaders = @{
    "apikey" = "sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
    "Authorization" = "Bearer sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}
$body = @{
    version = "1.0.76"
    apk_url = "https://whliroffubcqsalxdqfs.supabase.co/storage/v1/object/public/mess_images/HostelMess_final_1.0.76.apk"
} | ConvertTo-Json

Write-Output "Updating Supabase database..."
Invoke-RestMethod -Uri "https://whliroffubcqsalxdqfs.supabase.co/rest/v1/app_updates?id=eq.1" -Method Patch -Body $body -Headers $dbHeaders
Write-Output "Done!"
