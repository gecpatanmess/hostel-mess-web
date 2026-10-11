@echo off
echo ======================================================================
echo    Deploying Super Admin Web Portal to VERCEL
echo ======================================================================
echo.
echo Deploying 'super_admin_portal' directory to Vercel production...
echo (If this is your first time, it will ask you to login to your Vercel account)
echo.
cd super_admin_portal
call npx vercel --prod
cd ..
echo.
echo [DONE] Check above for your live Vercel URL!
echo ======================================================================
pause
