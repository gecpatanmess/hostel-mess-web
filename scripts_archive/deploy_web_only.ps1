Copy-Item "build\web\*" "d:\projects\hostel-mess-web\" -Recurse -Force
Set-Location "d:\projects\hostel-mess-web"
git add .
git commit -m "Deploy Unified Auth with Strong Passwords"
git push origin main
Write-Host "Deployed to GitHub!"
