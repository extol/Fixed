::==============================================================================
:: PROJECT:	Sonetics DECT Wireless Headset Test
::
:: DESCRIPTION:	
:: Modified by Tom Carlson on 8/31/2010 to strip out unneeded steps when doing a conversion from US to EU
:: on a Base Station
::
:: COMMAND LINE: EUConvert EU-Firmware-Filename.hex
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
:: set rtx_bps correctly to communicate with connected board
set rtx_duplex=1
set rtx_no_acknowledge=1

set rtx_bps=9600
set baudrate=9600
sendmail /3 2 3c 8 0 01 36 00 ?
if %ERRORLEVEL% EQU 0 GOTO :EOF

set rtx_bps=19200
set baudrate=19200
sendmail /3 2 3c 8 0 01 36 00 ?
if %ERRORLEVEL% EQU 0 GOTO :EOF

echo Can't read connected CVM Device
exit /b





:BAUD_9600
echo Setting BPS rate to 9600
SENDMAIL /%RTX_COM% 2 3b 8 0 1 7f 03 00 
set rtx_bps=9600
set baudrate=9600
set rtx_duplex=1
set rtx_no_acknowledge=1
GOTO :EOF

:BAUD_19200
echo Setting BPS rate to 19200
SENDMAIL /%RTX_COM% 2 3b 8 0 1 7f 03 01
set rtx_bps=19200
set baudrate=19200
set rtx_duplex=1
set rtx_no_acknowledge=1
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


:: ******** Main Program ************
:MAIN

:: Make sure various helper programs that we need are present in this directory

SET FileNotFound=0; 
call :Exists pk2cmd.exe
call :Exists PK2DeviceFile.dat
call :Exists fl6.exe
call :Exists floader.dll
call :Exists sendmail.exe
call :Exists cvmbsidset_eu.exe
call :Exists bs_id.txt
if %FileNotFound% NEQ 0 (
echo This is a utility file that is needed by this batch file.
echo Program Aborting
goto :End
)


:: if %1 is empty, (they didn't pass a filename) then ask for one
if %1.==. goto :PROMPT_FOR_FILENAME

goto :SET_FILENAME

:PROMPT_FOR_FILENAME
echo.
set eu_hex_filename="" 
set /p eu_hex_filename=What file would you like to write into the hardware?
if %eu_hex_filename%=="" (
exit /b
)
goto :TEST_FILENAME

:SET_FILENAME
set eu_hex_filename=%1


:TEST_FILENAME
:: Does their file exist?
SET FileNotFound=0; 
call :Exists %eu_hex_filename%
if %FileNotFound% NEQ 0 (
echo Program Aborting
goto :End
)


:: goto :HS2

:: OK, we have a filename to load into the PIC, so let's get on with  the show 

:: ************ BEGIN BS1_EU Section ***************
:: This is code ported from BS1_EU.BAT
:BS1 


cls
echo.
echo.
echo Sonetics DECT BaseStation EU Conversion
echo Plug the power cable in to power up the board
echo Plug the PICkit2 USB Dongle into J7
echo Plug the CVM Programming Dongle into J11
echo.
echo Make sure your Power Switch is OFF 
echo.
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


echo.
echo.
:: Program the CVM Firmware
echo Hold the CVM Programming Dongle Push Button DOWN 
echo    then turn Headset/Beltpack power switch to ON.
echo       wait for the PAIR LED to come on
echo          then Release theCVM Programming Dongle Push Button
echo.
PAUSE

call :DelayMe 2000
fl6 pp_onesw_v0179.hex

echo.
echo.
echo.

call :DelayMe 3000

:: make sure we can talk to CVM, even if just to set it's baud rate for later
call :BAUD_FIND

call :BAUD_9600


:: Prompt the user to cycle power properly to save EEPROM Values
call :PROMPT_POWERCYCLE

:: Make sure we can read the CVM
call :BAUD_FIND

@echo.
echo Setting EEPROM Defaults.
:: Set EE to defaults
SENDMAIL /%RTX_COM% 2 3a 0

call :DelayMe 1000

echo.
echo Writing EEPROM parameters
::Set FreqBandOffset
::SENDMAIL /%RTX_COM% 2 3b 8 0 1 36 00 ee 

::Set MaxRSSILevel
SENDMAIL /%RTX_COM% 2 3b 8 0 1 31 00 26 

::Set RSSTScanType
SENDMAIL /%RTX_COM% 2 3b 8 0 1 34 00 00

::Set Used Carriers
SENDMAIL /%RTX_COM% 2 3b 8 0 1 80 00 03
SENDMAIL /%RTX_COM% 2 3b 8 0 1 81 00 FF

::Set StartupMode
SENDMAIL /%RTX_COM% 2 3b 8 0 1 f3 00 11




:: Prompt the user to cycle power properly to save EEPROM Values
call :PROMPT_POWERCYCLE

echo Verifying  EEPROM parameters

:: Compare the EEPROM Values to what we wrote
SET CheckError=0

:: FreqBandOffset 
call :CHCKEEPROM "2 3c 8 0 01 36 00 ?" 00 

:: MaxRSSILevel 
call :CHCKEEPROM "2 3c 8 0 01 31 00 ?" 26

:: RSSTScanType  
call :CHCKEEPROM "2 3c 8 0 01 34 00 ?" 00 

:: Used Carriers
call :CHCKEEPROM "2 3c 8 0 1 80 00 ?" 03
call :CHCKEEPROM "2 3c 8 0 1 81 00 ?" FF 

:: StartupMode 
call :CHCKEEPROM "2 3c 8 0 01 F3 00 ?" 11

echo.

if %CheckError% NEQ 0 (
echo The EEPROM Values did not match.
echo Aborting Process
echo This unit has NOT been successfully converted to EU
exit /b
)

echo.
call :DelayMe 2000

call :BAUD_19200




:: ************ BEGIN BS2_EU Section ***************
:: This is code ported from BS2_EU.BAT
:BS2 

call :PROMPT_POWERSWITCH_CYCLE


call :DelayMe 2000

echo.
echo.
echo Setting Basestation ID
:: The FPN portion of the ID is derrived from the number contained in the file bs_id.txt.  
:: This file contains the FPN from the ID last programmed.   
:: The cvmbsidset app below reads the FPN number from the file, increments it, programs the new ID and 
:: saves the new FPN. 
cvmbsidset_eu

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

:: Prompt the user to cycle power properly to save EEPROM Values
call :PROMPT_POWERCYCLE

echo.
echo Programming EU Firmware into PIC
PK2CMD -pPIC18LF45J10 -e -j
PK2CMD -pPIC18LF45J10 -f%eu_hex_filename% -mP -r -j
PK2CMD -pPIC18LF45J10 -gP7FF8-7FFD -r -j  
  
echo.
echo.
echo Write the ID Number on the CVM Label
set /p IDNumber=<bs_id.txt
echo ID Number=%IDNumber%
echo.
echo Make sure that any hardware changes, such as R16, have been done
echo This unit has been successfully converted to EU
echo.


:End
exit /b