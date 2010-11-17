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


:SHOWEEPROM
for /f "tokens=*" %%a in ( 
'sendmail /%RTX_COM% 2 3c 8 0 01 %2 %1 ?' 
) do ( 
set param=%%a 
)
echo %1%2 - %param%
echo %1%2,%param% >> %dump_filename%
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
if %FileNotFound% NEQ 0 (
echo This is a utility file that is needed by this batch file.
echo Program Aborting
goto :ABORTPROGRAM
)

:: if %1 is empty, (they didn't pass a filename) then ask for one
if %1.==. goto :PROMPT_FOR_FILENAME

goto :SET_FILENAME

:PROMPT_FOR_FILENAME
echo.
set dump_filename="" 
set /p dump_filename=What file would you like to write EEPROM values to?
if %dump_filename%=="" (
exit /b
)
goto :TEST_FILENAME

:SET_FILENAME
set dump_filename=%1

:TEST_FILENAME
:: Does their file exist?
SET FileNotFound=0; 
call :Exists %dump_filename%
if %FileNotFound% EQU 0 (
echo File already Exists
echo Program Aborting
goto :ENDPROGRAM
)

:: Erase the PIC so it tristates it's serial output lines and doesn't 
:: interfere with talking to the CVM.  This eliminates the need to 
:: short TEST3 to ground.

::PK2CMD -pPIC18LF45J10 -e -j
::PK2CMD -pPIC18LF45J10 -f%bs-test3-active.hex -mP -r -j
::PK2CMD -pPIC18LF45J10 -gP7FF8-7FFD -r -j


call :BAUD_9600_STORE
call :BAUD_FIND

echo Reading  EEPROM parameters

call :SHOWEEPROM 00 00
call :SHOWEEPROM 00 01
call :SHOWEEPROM 00 02
call :SHOWEEPROM 00 03
call :SHOWEEPROM 00 04
call :SHOWEEPROM 00 05
call :SHOWEEPROM 00 06
call :SHOWEEPROM 00 07
call :SHOWEEPROM 00 08
call :SHOWEEPROM 00 09
call :SHOWEEPROM 00 0A
call :SHOWEEPROM 00 0B
call :SHOWEEPROM 00 0C
call :SHOWEEPROM 00 0D
call :SHOWEEPROM 00 0E
call :SHOWEEPROM 00 0F

call :SHOWEEPROM 00 10
call :SHOWEEPROM 00 11
call :SHOWEEPROM 00 12
call :SHOWEEPROM 00 13
call :SHOWEEPROM 00 14
call :SHOWEEPROM 00 15
call :SHOWEEPROM 00 16
call :SHOWEEPROM 00 17
call :SHOWEEPROM 00 18
call :SHOWEEPROM 00 19
call :SHOWEEPROM 00 1A
call :SHOWEEPROM 00 1B
call :SHOWEEPROM 00 1C
call :SHOWEEPROM 00 1D
call :SHOWEEPROM 00 1E
call :SHOWEEPROM 00 1F

call :SHOWEEPROM 00 20
call :SHOWEEPROM 00 21
call :SHOWEEPROM 00 22
call :SHOWEEPROM 00 23
call :SHOWEEPROM 00 24
call :SHOWEEPROM 00 25
call :SHOWEEPROM 00 26
call :SHOWEEPROM 00 27
call :SHOWEEPROM 00 28
call :SHOWEEPROM 00 29
call :SHOWEEPROM 00 2A
call :SHOWEEPROM 00 2B
call :SHOWEEPROM 00 2C
call :SHOWEEPROM 00 2D
call :SHOWEEPROM 00 2E
call :SHOWEEPROM 00 2F

call :SHOWEEPROM 00 30
call :SHOWEEPROM 00 31
call :SHOWEEPROM 00 32
call :SHOWEEPROM 00 33
call :SHOWEEPROM 00 34
call :SHOWEEPROM 00 35
call :SHOWEEPROM 00 36
call :SHOWEEPROM 00 37
call :SHOWEEPROM 00 38
call :SHOWEEPROM 00 39
call :SHOWEEPROM 00 3A
call :SHOWEEPROM 00 3B
call :SHOWEEPROM 00 3C
call :SHOWEEPROM 00 3D
call :SHOWEEPROM 00 3E
call :SHOWEEPROM 00 3F

call :SHOWEEPROM 00 40
call :SHOWEEPROM 00 41
call :SHOWEEPROM 00 42
call :SHOWEEPROM 00 43
call :SHOWEEPROM 00 44
call :SHOWEEPROM 00 45
call :SHOWEEPROM 00 46
call :SHOWEEPROM 00 47
call :SHOWEEPROM 00 48
call :SHOWEEPROM 00 49
call :SHOWEEPROM 00 4A
call :SHOWEEPROM 00 4B
call :SHOWEEPROM 00 4C
call :SHOWEEPROM 00 4D
call :SHOWEEPROM 00 4E
call :SHOWEEPROM 00 4F

call :SHOWEEPROM 00 50
call :SHOWEEPROM 00 51
call :SHOWEEPROM 00 52
call :SHOWEEPROM 00 53
call :SHOWEEPROM 00 54
call :SHOWEEPROM 00 55
call :SHOWEEPROM 00 56
call :SHOWEEPROM 00 57
call :SHOWEEPROM 00 58
call :SHOWEEPROM 00 59
call :SHOWEEPROM 00 5A
call :SHOWEEPROM 00 5B
call :SHOWEEPROM 00 5C
call :SHOWEEPROM 00 5D
call :SHOWEEPROM 00 5E
call :SHOWEEPROM 00 5F

call :SHOWEEPROM 00 60
call :SHOWEEPROM 00 61
call :SHOWEEPROM 00 62
call :SHOWEEPROM 00 63
call :SHOWEEPROM 00 64
call :SHOWEEPROM 00 65
call :SHOWEEPROM 00 66
call :SHOWEEPROM 00 67
call :SHOWEEPROM 00 68
call :SHOWEEPROM 00 69
call :SHOWEEPROM 00 6A
call :SHOWEEPROM 00 6B
call :SHOWEEPROM 00 6C
call :SHOWEEPROM 00 6D
call :SHOWEEPROM 00 6E
call :SHOWEEPROM 00 6F

call :SHOWEEPROM 00 70
call :SHOWEEPROM 00 71
call :SHOWEEPROM 00 72
call :SHOWEEPROM 00 73
call :SHOWEEPROM 00 74
call :SHOWEEPROM 00 75
call :SHOWEEPROM 00 76
call :SHOWEEPROM 00 77
call :SHOWEEPROM 00 78
call :SHOWEEPROM 00 79
call :SHOWEEPROM 00 7A
call :SHOWEEPROM 00 7B
call :SHOWEEPROM 00 7C
call :SHOWEEPROM 00 7D
call :SHOWEEPROM 00 7E
call :SHOWEEPROM 00 7F

call :SHOWEEPROM 00 80
call :SHOWEEPROM 00 81
call :SHOWEEPROM 00 82
call :SHOWEEPROM 00 83
call :SHOWEEPROM 00 84
call :SHOWEEPROM 00 85
call :SHOWEEPROM 00 86
call :SHOWEEPROM 00 87
call :SHOWEEPROM 00 88
call :SHOWEEPROM 00 89
call :SHOWEEPROM 00 8A
call :SHOWEEPROM 00 8B
call :SHOWEEPROM 00 8C
call :SHOWEEPROM 00 8D
call :SHOWEEPROM 00 8E
call :SHOWEEPROM 00 8F

call :SHOWEEPROM 00 90
call :SHOWEEPROM 00 91
call :SHOWEEPROM 00 92
call :SHOWEEPROM 00 93
call :SHOWEEPROM 00 94
call :SHOWEEPROM 00 95
call :SHOWEEPROM 00 96
call :SHOWEEPROM 00 97
call :SHOWEEPROM 00 98
call :SHOWEEPROM 00 99
call :SHOWEEPROM 00 9A
call :SHOWEEPROM 00 9B
call :SHOWEEPROM 00 9C
call :SHOWEEPROM 00 9D
call :SHOWEEPROM 00 9E
call :SHOWEEPROM 00 9F

call :SHOWEEPROM 00 A0
call :SHOWEEPROM 00 A1
call :SHOWEEPROM 00 A2
call :SHOWEEPROM 00 A3
call :SHOWEEPROM 00 A4
call :SHOWEEPROM 00 A5
call :SHOWEEPROM 00 A6
call :SHOWEEPROM 00 A7
call :SHOWEEPROM 00 A8
call :SHOWEEPROM 00 A9
call :SHOWEEPROM 00 AA
call :SHOWEEPROM 00 AB
call :SHOWEEPROM 00 AC
call :SHOWEEPROM 00 AD
call :SHOWEEPROM 00 AE
call :SHOWEEPROM 00 AF

call :SHOWEEPROM 00 B0
call :SHOWEEPROM 00 B1
call :SHOWEEPROM 00 B2
call :SHOWEEPROM 00 B3
call :SHOWEEPROM 00 B4
call :SHOWEEPROM 00 B5
call :SHOWEEPROM 00 B6
call :SHOWEEPROM 00 B7
call :SHOWEEPROM 00 B8
call :SHOWEEPROM 00 B9
call :SHOWEEPROM 00 BA
call :SHOWEEPROM 00 BB
call :SHOWEEPROM 00 BC
call :SHOWEEPROM 00 BD
call :SHOWEEPROM 00 BE
call :SHOWEEPROM 00 BF

call :SHOWEEPROM 00 C0
call :SHOWEEPROM 00 C1
call :SHOWEEPROM 00 C2
call :SHOWEEPROM 00 C3
call :SHOWEEPROM 00 C4
call :SHOWEEPROM 00 C5
call :SHOWEEPROM 00 C6
call :SHOWEEPROM 00 C7
call :SHOWEEPROM 00 C8
call :SHOWEEPROM 00 C9
call :SHOWEEPROM 00 CA
call :SHOWEEPROM 00 CB
call :SHOWEEPROM 00 CC
call :SHOWEEPROM 00 CD
call :SHOWEEPROM 00 CE
call :SHOWEEPROM 00 CF

call :SHOWEEPROM 00 D0
call :SHOWEEPROM 00 D1
call :SHOWEEPROM 00 D2
call :SHOWEEPROM 00 D3
call :SHOWEEPROM 00 D4
call :SHOWEEPROM 00 D5
call :SHOWEEPROM 00 D6
call :SHOWEEPROM 00 D7
call :SHOWEEPROM 00 D8
call :SHOWEEPROM 00 D9
call :SHOWEEPROM 00 DA
call :SHOWEEPROM 00 DB
call :SHOWEEPROM 00 DC
call :SHOWEEPROM 00 DD
call :SHOWEEPROM 00 DE
call :SHOWEEPROM 00 DF

call :SHOWEEPROM 00 E0
call :SHOWEEPROM 00 E1
call :SHOWEEPROM 00 E2
call :SHOWEEPROM 00 E3
call :SHOWEEPROM 00 E4
call :SHOWEEPROM 00 E5
call :SHOWEEPROM 00 E6
call :SHOWEEPROM 00 E7
call :SHOWEEPROM 00 E8
call :SHOWEEPROM 00 E9
call :SHOWEEPROM 00 EA
call :SHOWEEPROM 00 EB
call :SHOWEEPROM 00 EC
call :SHOWEEPROM 00 ED
call :SHOWEEPROM 00 EE
call :SHOWEEPROM 00 EF

call :SHOWEEPROM 00 F0
call :SHOWEEPROM 00 F1
call :SHOWEEPROM 00 F2
call :SHOWEEPROM 00 F3
call :SHOWEEPROM 00 F4
call :SHOWEEPROM 00 F5
call :SHOWEEPROM 00 F6
call :SHOWEEPROM 00 F7
call :SHOWEEPROM 00 F8
call :SHOWEEPROM 00 F9
call :SHOWEEPROM 00 FA
call :SHOWEEPROM 00 FB
call :SHOWEEPROM 00 FC
call :SHOWEEPROM 00 FD
call :SHOWEEPROM 00 FE
call :SHOWEEPROM 00 FF

:ENDPROGRAM
exit /b

:ABORTPROGRAM
echo.
echo.
echo There was an error.  This part has NOT been read
echo Program Aborting Now
exit /b