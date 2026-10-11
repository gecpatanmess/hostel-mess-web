@echo off
echo ======================================================================
echo    Hostel Mess Management - Super Admin Web Portal Deployment
echo ======================================================================
echo.
echo Deploying web portal to Firebase Hosting (hostel-mess-21845)...
echo.
call firebase deploy --only hosting --project hostel-mess-21845
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [NOTE] If you saw an authorization error:
    echo Please make sure you are logged in with the Google account that has
    echo owner/editor access to project 'hostel-mess-21845'.
    echo You can log in anytime by running: firebase login --reauth
    echo.
) else (
    echo.
    echo [SUCCESS] Web portal deployed successfully to Firebase Hosting!
    echo.
)
pause
