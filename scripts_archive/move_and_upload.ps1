 = "C:\Users\daxpa\Downloads\apk_hostel_mess"
 = "D:\projects\hostelmessmanagment\build\app\outputs\flutter-apk\app-release.apk"
 = "\HostelMess.apk"

# Ensure directory exists
if (-not (Test-Path )) {
    New-Item -ItemType Directory -Force -Path 
}

# Remove old APKs
Remove-Item "\*.apk" -Force -ErrorAction SilentlyContinue

# Copy new APK
Copy-Item  -Destination  -Force

Write-Host "Moved APK successfully to "

cd D:\projects\hostel-backend
node upload_apk_74.js ""
