@rem Test Oracle Wallet Connections
setlocal ENABLEDELAYEDEXPANSION
@echo.USERNAME=%USERNAME%
@echo.COMPUTERNAME=%COMPUTERNAME%
@rem Try to guess Oracle Service Name from ComputerName
set env=%COMPUTERNAME:~-2,1%
if "%env%" == "D"   set local=pond.world
if "%env%" == "U"   set local=ponu.world
if "%env%" == "T"   set local=pont.world
if "%env%" == "P"   set local=ponp.world
if "%local%" == ""  set local=pond.world
:cont
@rem echo.env=%env%
@echo.local=%local%
(echo.show user
echo.select * from global_name;
echo.exit
)|sqlplus -L /@%local%

@echo.ERRORLEVEL=%ERRORLEVEL%
:end
pause
endlocal
