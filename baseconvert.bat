::==============================================================================
:: PROJECT:	Sonetics DECT Wireless Generation 1
::
:: DESCRIPTION:	
:: Load Base Station CVM and PIC with Code and Configure CVM for either EU or US operation
::
:: COMMAND LINE: BaseConvert EU Firmware-Filename.hex
:: COMMAND LINE: BaseConvert US Firmware-Filename.hex
::
:: RETURN FORMAT: None
::
::  NOTE:  Currently set up for comm port COM3.  To change comm port, replace 9 with the new com port number in the 
::	"set rtx_com=3" line below and in the HS2.BAT file.  Also replace 9 with the new comm port number in the
::	 "Comport=3" line in the fl6.cfg file.
::==============================================================================
@echo off
SETLOCAL EnableDelayedExpansion

set rtx_com=3
if [%RTX_COM%]==[] (
echo RTX_COM not set!
exit /b
) 
set rtx_duplex=1
set rtx_no_acknowledge=1
set rtx_bps=19200
set baudrate=19200


goto :MAIN

:: ******** Functions ************
:PROMPT_POWERSWITCH_CYCLE
:: Instruct user to turn off an on power switch, nut not the battery
echo.
echo Turn off Power Switch on Device
echo   Wait a few seconds
echo     Turn on Power Switch on Device
echo.
PAUSE
GOTO :EOF

:PROMPT_POWERCYCLE
:: Instruct user on power down/up sequence
echo.
echo Turn off Power Switch on Device
echo   Count to 5
echo      UNPLUG Battery from Device
echo       PLUG Battery into Device
echo   Turn ON Power Switch on Device
echo Count to 5
echo.
PAUSE
GOTO :EOF


:BAUD_FIND
:: set rtx_bps correctly to communicate with connected CVM
:: Tries 9600 and 19200 to see which one the connected CVM is communicating at
set rtx_duplex=1
set rtx_no_acknowledge=1

set rtx_bps=19200
set baudrate=19200
sendmail /3 2 3c 8 0 01 36 00 ? >NUL
if %ERRORLEVEL% EQU 0 GOTO :EOF

set rtx_bps=9600
set baudrate=9600
sendmail /3 2 3c 8 0 01 36 00 ? >NUL
if %ERRORLEVEL% EQU 0 GOTO :EOF

:: Tell caller that we failed to set the baud rate, so they can abort program
:: Do that by reporting an error level of 1
echo.
echo.
echo CVM Programming Dongle Failed to Communicate with CVM
exit /b 1
GOTO :EOF


:BAUD_9600_STORE
echo Setting BPS rate to 9600 - Must Power Cycle CVM to get new baud rate
SENDMAIL /%RTX_COM% 2 3b 8 0 1 7f 03 00 
GOTO :EOF

:BAUD_19200_STORE
echo Setting BPS rate to 19200 - Must Power Cycle CVM to get new baud rate
SENDMAIL /%RTX_COM% 2 3b 8 0 1 7f 03 01
GOTO :EOF

:Exists
set testfilename=%1
if not exist %testfilename% (
  echo %testfilename% not found.
  SET FileNotFound=1;   
)
GOTO :EOF


:DelayMe
SET delaytime=%1
:: Wait XXX miliseconds before continuing
echo Delay %delaytime%ms
PING 1.1.1.1 -n 1 -w %delaytime% >NUL
GOTO :EOF

:DeQuote
SET _DeQuoteVar=%1
CALL SET _DeQuoteString=%%!_DeQuoteVar!%%
IF [!_DeQuoteString:~0^,1!]==[^"] (
IF [!_DeQuoteString:~-1!]==[^"] (
SET _DeQuoteString=!_DeQuoteString:~1,-1!
) ELSE (GOTO :EOF)
) ELSE (GOTO :EOF)
SET !_DeQuoteVar!=!_DeQuoteString!
SET _DeQuoteVar=
SET _DeQuoteString=
GOTO :EOF


:CHCKEEPROM
:: Uses Global variable CheckError to alert calling routine to problem

SET QueryString=%1
SET CompareValue=%2

:: Get rid of quotes around QueryString
CALL :dequote QueryString 

for /f "tokens=*" %%a in ( 
'sendmail /%RTX_COM%  %QueryString%' 
) do ( 
set param=%%a 
)
:: Case Insenstive Compare
if /I %param% EQU %CompareValue% (
echo %param% === %CompareValue%
) else (
SET CheckError=1;
echo %param% NOT %CompareValue%
)
goto :EOF


:SETUP_EEPROMVARS_EU
echo Setting EEPROM Defaults for EU DECT
:: Set EE to defaults
SENDMAIL /%RTX_COM% 2 3a 0
call :DelayMe 500
echo Writing EEPROM parameters
::Set EU FreqBandOffset
SENDMAIL /%RTX_COM% 2 3b 8 0 1 36 00 00
::Set EU MaxRSSILevel
SENDMAIL /%RTX_COM% 2 3b 8 0 1 31 00 26 
::Set EU RSSTScanType
SENDMAIL /%RTX_COM% 2 3b 8 0 1 34 00 00
::Set EU Used Carriers
SENDMAIL /%RTX_COM% 2 3b 8 0 1 80 00 03
SENDMAIL /%RTX_COM% 2 3b 8 0 1 81 00 FF
::Set EU StartupMode
SENDMAIL /%RTX_COM% 2 3b 8 0 1 f3 00 11
goto :EOF

:SETUP_EEPROMVARS_US
echo Setting EEPROM Defaults for US DECT6
:: Set EE to defaults
SENDMAIL /%RTX_COM% 2 3a 0
call :DelayMe 500
echo Writing EEPROM parameters
::Set US FreqBandOffset
SENDMAIL /%RTX_COM% 2 3b 8 0 1 36 00 ee
::Set US MaxRSSILevel  Fudge in the MaxRSSI Level to 26 for lab test (this should be set with test jig)
SENDMAIL /%RTX_COM% 2 3b 8 0 1 31 00 26 
::Set US RSSTScanType
SENDMAIL /%RTX_COM% 2 3b 8 0 1 34 00 01
::Set US Used Carriers
SENDMAIL /%RTX_COM% 2 3b 8 0 1 80 00 03
SENDMAIL /%RTX_COM% 2 3b 8 0 1 81 00 e0
::Set US StartupMode 
SENDMAIL /%RTX_COM% 2 3b 8 0 1 f3 00 21
goto :EOF

:CHECK_EEPROMVARS_EU
echo Verifying EEPROM Variables for EU DECT
:: Compare the EEPROM Values to what we wrote
SET CheckError=0
:: FreqBandOffset 
call :CHCKEEPROM "2 3c 8 0 01 36 00 ?" 00 
:: MaxRSSILevel 
call :CHCKEEPROM "2 3c 8 0 01 31 00 ?" 26
:: RSSTScanType  
call :CHCKEEPROM "2 3c 8 0 01 34 00 ?" 00
:: Used Carriers
call :CHCKEEPROM "2 3c 8 0 01 80 00 ?" 03
call :CHCKEEPROM "2 3c 8 0 01 81 00 ?" FF
:: StartupMode 
call :CHCKEEPROM "2 3c 8 0 01 F3 00 ?" 11
echo.
if %CheckError% NEQ 0 (
echo The EEPROM Values did not match.
echo Aborting Process
echo This unit has NOT been successfully converted
)
goto :EOF

:CHECK_EEPROMVARS_US
echo Verifying EEPROM Variables for US DECT6
:: Compare the EEPROM Values to what we wrote
SET CheckError=0
:: FreqBandOffset 
call :CHCKEEPROM "2 3c 8 0 01 36 00 ?" EE 
:: MaxRSSILevel
call :CHCKEEPROM "2 3c 8 0 01 31 00 ?" 26
:: RSSTScanType 
call :CHCKEEPROM "2 3c 8 0 01 34 00 ?" 01 
:: Used Carriers
call :CHCKEEPROM "2 3c 8 0 01 80 00 ?" 03
call :CHCKEEPROM "2 3c 8 0 01 81 00 ?" E0 
:: StartupMode
call :CHCKEEPROM "2 3c 8 0 01 F3 00 ?" 21
echo.
if %CheckError% NEQ 0 (
echo The EEPROM Values did not match.
echo Aborting Process
echo This unit has NOT been successfully converted
)
goto :EOF


:: ******** Main Program ************
:MAIN

:: Make sure various helper programs that we need are present in this directory

SET FileNotFound=0; 
call :Exists bs-test3-active.hex
call :Exists pk2cmd.exe
call :Exists PK2DeviceFile.dat
call :Exists fl6.exe
call :Exists floader.dll
call :Exists sendmail.exe
call :Exists cvmbsidset_eu.exe
call :Exists cvmbsidset.exe
call :Exists bs_id.txt
if %FileNotFound% NEQ 0 (
echo This is a utility file that is needed by this batch file.
echo Program Aborting
goto :ENDPROGRAM
)

:: if %2 is empty, (they didn't tell us if they wanted US or EU) then prompt them
if %2.==. (
echo The syntax of the command is incorrect
echo.
echo To configure as an EU Base Station 
echo COMMAND LINE: BaseConvert EU Firmware-Filename.hex
echo.
echo To configure as a US Base Station
echo COMMAND LINE: BaseConvert US Firmware-Filename.hex
echo.
ENDLOCAL
exit /b
)

:SET_REGION
set region=%1

:TEST_REGION
:: Case Insenstive Compare
if /I %region% EQU us (
echo Region: %region%
) else (
if /I %region% EQU eu (
echo Region: %region%
) else (
echo Region %region% not recognized
goto :ABORTPROGRAM
)
)

:SET_FILENAME
set hex_filename=%2

:TEST_FILENAME
:: Does their file exist?
SET FileNotFound=0; 
call :Exists %hex_filename%
if %FileNotFound% NEQ 0 (
goto :ABORTPROGRAM
)
echo Filename: %hex_filename%

:: OK, we have a filename to load into the PIC, so let's get on with  the show 

echo.
echo Sonetics DECT BaseStation Convert
echo Plug the power cable in to power up the board
echo Plug the PICkit2 USB Dongle into J1
echo Plug the CVM Programming Dongle into J3
echo.
echo Preparing to erase program in PIC so it doesn't interfere with CVM Programming
echo hit CTRL-C to abort
PAUSE

:: Erase the PIC so it tristates it's serial output lines and doesn't 
:: interfere with talking to the CVM.  This eliminates the need to 
:: short TEST3 to ground.
PK2CMD -pPIC18LF45J10 -e -j
PK2CMD -pPIC18LF45J10 -f%bs-test3-active.hex -mP -r -j
PK2CMD -pPIC18LF45J10 -gP7FF8-7FFD -r -j
:: echo %ERRORLEVEL%
:: if %ERRORLEVEL% GTR 0 exit /B


:: if we're already at 9600, then the 19200 store will work
:: if we're already at 19200, the 19200 won't work, but it doesn't matter, since we're already 19200!
set rtx_bps=9600
set baudrate=9600
call :BAUD_19200_STORE

echo.
echo.
:: Program the CVM Firmware
echo Hold the CVM Programming Dongle Push Button DOWN 
echo    then turn BaseStation power switch to ON.
echo       wait for the PAIR LED to come on
echo          then Release the 'CVM Programming Dongle' Push Button
echo.

PAUSE
call :DelayMe 2000
FL6 pp_onesw_v0179.hex
::FL6 pp_onesw_v0183.hex
:: echo.
:: echo %ERRORLEVEL%
:: if %errorlevel% neq 0 goto :ABORTPROGRAM
:: FL6.exe is not correctly reporting errorlevel, so we can't debug based on it.

:: Make sure we can read the CVM
call :BAUD_FIND
if %errorlevel% equ 0 goto :GOODCVM

::Woops, we failed to talk to the CVM, let's try one more time
call :BAUD_FIND
call :BAUD_19200_STORE
echo Remove Power from the BaseStation.
echo   Hold the 'CVM Programming Dongle' Push Button DOWN 
echo      then return power to BaseStation.
echo         wait for the PAIR LEDS to come on
echo            then Release the 'CVM Programming Dongle' Push Button
PAUSE
call :DelayMe 2000
FL6 pp_onesw_v0179.hex
::FL6 pp_onesw_v0183.hex
call :BAUD_FIND
if %errorlevel% neq 0 goto :ABORTPROGRAM
call :BAUD_19200_STORE

:GOODCVM
echo.
::call :BAUD_19200_STORE
call :BAUD_9600_STORE

:: Prompt the user to cycle power properly to save EEPROM Values
call :PROMPT_POWERCYCLE
call :BAUD_FIND

:: Write configuration values to EEPROM
if /I %region% EQU us (
call :SETUP_EEPROMVARS_US
) else (
call :SETUP_EEPROMVARS_EU
)

:: Prompt the user to cycle power properly to save EEPROM Values
call :PROMPT_POWERCYCLE
call :BAUD_FIND

:: Check that we wrote the correct values to EEPROM
SET CheckError=0
if /I %region% EQU us (
call :CHECK_EEPROMVARS_US
) else (
call :CHECK_EEPROMVARS_EU
)
if %CheckError% NEQ 0 (
goto :ABORTPROGRAM
)

echo.
echo.
echo Setting Basestation ID
:: The FPN portion of the ID is derrived from the number contained in the file bs_id.txt.  
:: This file contains the FPN from the ID last programmed.   
:: The cvmbsidset app below reads the FPN number from the file, increments it, programs the new ID and 
:: saves the new FPN. 

:: Write the ID to the part
if /I %region% EQU us (
cvmbsidset
) else (
cvmbsidset_eu
)

call :DelayMe 1500

for /f "tokens=*" %%a in ( 
'SENDMAIL /%RTX_COM% 02 5d 1C ?' 
) do ( 
set new_id=%%a 
)
echo Read IPEI= %new_id%

echo The two values above must match exactly, or unit fails.
echo.
echo Do they match?  Great!  
PAUSE


:: We MUST set the CVM back to 19200, or the PIC won't be able to talk to it!
call :BAUD_19200_STORE

echo.
echo Programming %region% Firmware into PIC
PK2CMD -pPIC18LF45J10 -e -j
PK2CMD -pPIC18LF45J10 -f%hex_filename% -mP -r -j
PK2CMD -pPIC18LF45J10 -gP7FF8-7FFD -r -j  
  
echo.
echo.
echo Write the ID Number on the CVM Label
set /p IDNumber=<bs_id.txt
echo ID Number=%IDNumber%
echo.
echo Make sure that any hardware changes, such as R16, have been done
echo This unit has been successfully converted to %region%.
echo.


:ENDPROGRAM
ENDLOCAL
exit /b

:ABORTPROGRAM
echo.
echo.
echo There was an error.  This part has NOT been successfully programmed
echo Program Aborting Now
ENDLOCAL
exit /b
ENDLOCAL