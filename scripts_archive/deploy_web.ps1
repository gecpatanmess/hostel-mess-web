Remove-Item -Recurse -Force "d:\projects\hostel-mess-web\*" -Exclude ".git" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force "d:\projects\hostelmessmanagment\build\web\*" "d:\projects\hostel-mess-web\"
git -C d:\projects\hostel-mess-web add .
git -C d:\projects\hostel-mess-web commit -m "Deploy v4 - Admin Flow, Unified Login, Circular Crop"
git -C d:\projects\hostel-mess-web push origin main
