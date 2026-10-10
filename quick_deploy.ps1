Write-Host "Building Web..."
flutter build web
Write-Host "Copying Web files..."
Copy-Item -Path .\build\web\* -Destination .\ -Recurse -Force
Write-Host "Pushing to GitHub..."
git add .
git commit -m "fix: revert splash screen logo back to app logo (logo.jpg) and bump version to 1.0.99"
git push

Write-Host "Building APK..."
flutter build apk --split-per-abi

Write-Host "Deploying APK..."
$apkPath = "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
$destPath = "APK_Releases\HostelMess_final_1.0.99.apk"
Copy-Item -Path $apkPath -Destination $destPath -Force

$headers = @{
    "apikey" = "sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
    "Authorization" = "Bearer sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
    "Content-Type" = "application/vnd.android.package-archive"
}
$bytes = [System.IO.File]::ReadAllBytes($destPath)
Invoke-RestMethod -Uri "https://whliroffubcqsalxdqfs.supabase.co/storage/v1/object/mess_images/HostelMess_final_1.0.99.apk" -Method Post -Body $bytes -Headers $headers

$dbHeaders = @{
    "apikey" = "sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
    "Authorization" = "Bearer sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}
$body = @{
    version = "1.0.99"
    apk_url = "https://whliroffubcqsalxdqfs.supabase.co/storage/v1/object/public/mess_images/HostelMess_final_1.0.99.apk"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://whliroffubcqsalxdqfs.supabase.co/rest/v1/app_updates?id=eq.1" -Method Patch -Body $body -Headers $dbHeaders
Write-Host "All done!"
