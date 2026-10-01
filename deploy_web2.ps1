echo "Copying web build..."
Copy-Item -Path build\web\* -Destination ..\hostel-mess-web -Recurse -Force
cd ..\hostel-mess-web
git add .
git commit -m "Update web build v1.0.28 - About Developers"
git push
cd ..\hostelmessmanagment
echo "Done"
