@echo off
setlocal
set "VIVADO=C:\Xilinx\Vivado\2020.2\bin\vivado.bat"
if not exist "%VIVADO%" (
  echo ERROR: Vivado 2020.2 was not found at %VIVADO%
  exit /b 1
)
pushd "%~dp0.."
call "%VIVADO%" -mode batch -source vivado\program_board.tcl -log build\vivado\program_board.log -journal build\vivado\program_board.jou
set RESULT=%ERRORLEVEL%
popd
endlocal & exit /b %RESULT%
