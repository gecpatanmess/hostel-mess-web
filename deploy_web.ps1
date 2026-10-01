echo "Copying web build..."
Copy-Item -Path build\web\* -Destination ..\hostel-mess-web -Recurse -Force
cd ..\hostel-mess-web
git add .
git commit -m "Deploy 1.0.28 Admin About Developers Fix"
git push origin main
echo "Done"
