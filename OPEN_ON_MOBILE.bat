@echo off
title Hostel Mess - Open Super Admin Portal on Mobile
echo ======================================================================
echo    HOSTEL MESS MANAGEMENT - SUPER ADMIN MOBILE ACCESS
echo ======================================================================
echo.
cd /d "%~dp0super_admin_portal"
node server.js
pause
