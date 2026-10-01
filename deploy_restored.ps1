echo "Pushing flutter-source..."
cd d:\projects\hostelmessmanagment
git add lib\main.dart
git commit -m "Restore Email OTP and patches"
git push -u origin HEAD:flutter-source --force

echo "Copying web build..."
cd d:\projects\hostelmessmanagment
Copy-Item -Path build\web\* -Destination ..\hostel-mess-web\ -Recurse -Force

echo "Pushing to Vercel/GitHub Pages..."
cd d:\projects\hostel-mess-web
git add .
git commit -m "Deploy restored v1.0.29 (Email OTP)"
git push origin main
