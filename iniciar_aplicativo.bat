@echo off
REM Inicia el aplicativo con el servidor integrado de PHP (sin Apache).
REM Usa el PHP de XAMPP (C:\xampp\php) o el que este en el PATH. Rutas relativas a esta carpeta.
cd /d "%~dp0"
set "PHP_EXE="
if exist "C:\xampp\php\php.exe" set "PHP_EXE=C:\xampp\php\php.exe"
if not defined PHP_EXE for %%P in (php.exe) do if not "%%~$PATH:P"=="" set "PHP_EXE=%%~$PATH:P"
if not defined PHP_EXE (
  echo No se encontro PHP 8. Instale XAMPP en C:\xampp o agregue PHP al PATH.
  pause
  exit /b 1
)
start "" http://localhost:8000
"%PHP_EXE%" -S localhost:8000 -t "%~dp0"
