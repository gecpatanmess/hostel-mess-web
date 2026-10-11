@echo off
echo ======================================================================
echo    Hostel Mess Management - Super Admin Web Portal (Local Server)
echo ======================================================================
echo.
echo Opening Super Admin Web Portal at http://localhost:5000 ...
echo Press Ctrl+C in this window to stop the server when done.
echo.
start "" "http://localhost:5000"
call npx serve super_admin_portal -l 5000
pause
