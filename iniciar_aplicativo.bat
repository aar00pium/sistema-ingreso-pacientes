@echo off
REM Inicia el aplicativo con el servidor integrado de PHP (sin Apache).
REM Requiere PHP 8 con pdo_mysql. Cambiar la ruta si PHP esta en otra carpeta.
set PHP_EXE=C:\xampp\php\php.exe
cd /d "%~dp0"
start "" http://localhost:8000
"%PHP_EXE%" -S localhost:8000
