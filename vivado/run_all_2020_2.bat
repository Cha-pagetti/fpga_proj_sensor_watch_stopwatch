@echo off
setlocal
set "VIVADO=C:\Xilinx\Vivado\2020.2\bin\vivado.bat"
if not exist "%VIVADO%" (
  echo ERROR: Vivado 2020.2 was not found at %VIVADO%
  echo Edit VIVADO in this file if your installation path is different.
  exit /b 1
)
pushd "%~dp0.."
call "%VIVADO%" -mode batch -source vivado\run_simulations.tcl -log build\vivado\simulations.log -journal build\vivado\simulations.jou
if errorlevel 1 exit /b 1
call "%VIVADO%" -mode batch -source vivado\run_rtl_elaboration.tcl -log build\vivado\rtl_elaboration.log -journal build\vivado\rtl_elaboration.jou
if errorlevel 1 exit /b 1
call "%VIVADO%" -mode batch -source vivado\run_build.tcl -log build\vivado\build.log -journal build\vivado\build.jou
if errorlevel 1 exit /b 1
echo PASS: simulation, RTL elaboration, synthesis, implementation, and bitstream
popd
endlocal
