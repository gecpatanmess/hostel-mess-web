Write-Host "Building ARM64 APK..."
flutter build apk --release --target-platform android-arm64
if ( -ne 0) { exit }

Write-Host "Proceeding with deployment..."
# Save to the user's specific folder
New-Item -ItemType Directory -Force -Path "C:\Users\daxpa\Downloads\apk_hostel_mess"
# Remove old APKs
Remove-Item -Path "C:\Users\daxpa\Downloads\apk_hostel_mess\*" -Include *.apk -Force -Recurse

# Copy new APK
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "C:\Users\daxpa\Downloads\apk_hostel_mess\HostelMess_final.apk" -Force
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "d:\projects\hostel-mess-web\HostelMess_final.apk" -Force

Write-Host "Deployed to local folder!"

Set-Location "d:\projects\hostel-backend"
node upload_apk_74.js
Write-Host "Deployed to Supabase!"
