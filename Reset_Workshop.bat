@echo off
:: Workshop Reset - Axis AQS Data Visualization
:: Double-click this file on Windows to run it.

:: Force local C: drive to avoid UNC path errors
C:
cd \

set PROJECT_DIR=C:\Users\TTC\Axis_AQS_Data_Visualization
set COMPOSE_FILE=docker-compose.ming.yml

echo.
echo ======================================
echo   Workshop Reset Script
echo ======================================
echo.

:: Step 1 - Tear down Docker containers and volumes
echo [1/2] Stopping Docker containers and removing volumes...

if exist "%PROJECT_DIR%" (
    cd /d "%PROJECT_DIR%"
    if errorlevel 1 (
        echo ERROR: Could not enter %PROJECT_DIR%
        pause
        exit /b 1
    )

    docker-compose -f "%COMPOSE_FILE%" down -v
    if errorlevel 1 (
        echo.
        echo WARNING: Docker-compose reported an error.
        echo          Make sure Docker Desktop is running and try again.
        pause
        exit /b 1
    )
    echo       Docker shutdown complete.
) else (
    echo       Folder not found - skipping Docker shutdown
)

:: Step 2 - Delete the project folder
echo.
echo [2/2] Deleting project folder...

if exist "%PROJECT_DIR%" (
    rd /s /q "%PROJECT_DIR%"
    if errorlevel 1 (
        echo.
        echo ERROR: Could not delete %PROJECT_DIR%
        echo        It may be in use or you may need admin rights.
        pause
        exit /b 1
    )
    echo       Folder deleted successfully.
) else (
    echo       Folder already gone - nothing to delete
)

echo.
echo ======================================
echo   Reset complete! Ready for next use.
echo ======================================
echo.
pause
