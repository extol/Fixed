::==============================================================================
:: $Header:   J:/sw/cvm/TEST/COMMON/vcs/Writeid.bat_v   1.0   13 Aug 2003 15:44:02   SS  $
::
:: PROJECT: Gap-Common, BS
::
:: DESCRIPTION: Programmes the RFPI of the base into EE-Prom.
::
:: COMMAND LINE: WRITE_ID RFPI
::
:: PARAMETER VALUES:
::
:: RFPI: (5 bytes separated by spaces)
::
::
:: RETURN FORMAT: None
::
:: Write:
::
:: TASK.....: 2  : EEPROMTASK
:: PRIMITIVE: 5d : TEST_CMD_req
:: Parm[0] :  1B : TC_WRITE_ID
:: Parm[1] :  %1 : RFPI byte 1 (MSB)
:: Parm[2] :  %2 : RFPI byte 2
:: Parm[3] :  %3 : RFPI byte 3
:: Parm[4] :  %4 : RFPI byte 4
:: Parm[5] :  %5 : RFPI byte 5 (LSB)
::
::
:: Read:
::
:: TASK.....: 02: EEPROMTASK
:: PRIMITIVE: 5D: TEST_CMD_req
:: Parm[0]:   1C: TC_READ_ID
:: Parm[1]:   01: Dummy
:: Parm[2]:   05: Number of bytes returned
::
:: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
:: The information in this document is confidential and sole property of
:: RTX Research A/S. (c) Copyright 1998 by RTX Research A/S.
::==============================================================================
@if [%RTX_COM%]==[] goto NoComPort
@if [%1]==[] goto Read
@if [%2]==[] goto Read
@if [%3]==[] goto Read
@if [%4]==[] goto Read
@if [%5]==[] goto Read
@SENDMAIL /%RTX_COM% 02 5D 1B %1 %2 %3 %4 %5
:Read (skip the read for the test platform)
:@ECHO RFPI/IPEI set to:
:@sendmail /%RTX_COM% 02 5D 1C 01 05 ?
@Goto End
:NoComPort
@echo RTX_COM not set!
:End
