::==============================================================================
:: $Header:   J:/sw/cvm/test/common/vcs/ReadId.bat_v   1.0   19 Feb 2003 18:10:10   MSJ  $
::
:: PROJECT: GAP-COMMON HS/BS
::
:: DESCRIPTION: Reads IPEI/RFPI from EEPROM
::
:: COMMAND LINE: ReadId.bat
::
:: PARAMETER VALUES: None
::
::
:: RETURN FORMAT:
::
:: TASK.....:  2 : EEPROMTASK
:: PRIMITIVE: 5d : TEST_CMD_req
:: FUNCTION:  1C : TC_READ_ID
::
:: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
:: The information in this document is confidential and sole property of
:: RTX Research A/S. (c) Copyright 1998 by RTX Research A/S.
::==============================================================================
@if [%RTX_COM%]==[] goto NoComPort
@SENDMAIL /%RTX_COM% 02 5d 1C ?
@Goto End
:NoComPort
@echo RTX_COM not set!
@Goto End
:NoParm
@echo Parameter missing!
:End
