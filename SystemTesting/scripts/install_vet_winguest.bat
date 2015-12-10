:: ############################################################################
:: #Copyright (C) 2009 VMWare, Inc.
:: # All Rights Reserved
:: ############################################################################
:: This batch file contains functions to install STAF, enable plaintext
:: password, install perl, disable/enable firewall via vmrun when STAF and
:: Perl are not installed/running

:: Acceptable options are: plaintext, perl, vet fon, and foff

:: TODO: There is no error checking in this file -- needs to be added
set option=%1
set arch=%2
set plaintext=plaintext
set perl=perl
set vetstaf=vet
set firewallon=fon
set firewalloff=foff

IF %option% equ %plaintext% GOTO SET_PLAINTEXT
IF %option% equ %perl% GOTO INSTALL_PERL
IF %option% equ %vetstaf% GOTO INSTALL_VETSTAF
IF %option% equ %firewallon% GOTO FIREWALL_ON
IF %option% equ %firewalloff% GOTO FIREWALL_OFF

GOTO ERROR

: SET_PLAINTEXT
echo Setting plaintextpassword registry key
reg add HKLM\system\currentcontrolset\services\lanmanworkstation\parameters ^
	/v enableplaintextpassword /t REG_DWORD /d 0x1 /f

GOTO EXIT

: INSTALL_PERL
echo Installing perl...
:: Mount setup automation dir from master controller,
:: it has all the required setup scripts
net use K: \\10.20.84.162\install /user:root ca$hc0w /persistent:no
IF ERRORLEVEL 0 GOTO CONTINUE_INSTALL
IF ERRORLEVEL 1 GOTO EXIT

: CONTINUE_INSTALL
:: Copy the stuff locally
xcopy /E /Y K:\* C:\vmqa\
cd C:\
net use /delete K:

:: Go to local dir and run the install script
cd C:\vmqa
perlInstall.bat %arch% > perl.log

GOTO EXIT

: INSTALL_VETSTAF

echo Setting up all the other env stuff...

echo Turning off firewall
reg add HKLM\system\currentcontrolset\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile ^
	/v EnableFirewall /t REG_DWORD /d 0x0 /f

echo Enabling autologon
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" ^
	/v DefaultUserName /t REG_SZ /d Administrator /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" ^
	/v DefaultPassword /t REG_SZ /d ca$hc0w /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" ^
	/v AutoAdminLogon /t REG_SZ /d 1 /f

echo Disabling event tracker
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Reliability ^
	/v ShutdownReasonUI /t REG_DWORD /d 0x0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" ^
	/v ShutdownReasonUI /t REG_DWORD /d 0x0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" ^
	/v ShutdownReasonOn /t REG_DWORD /d 0x0 /f

echo Configuring kernel to dump full memory
wmic recoveros set DebugInfoType = 1

echo Enabling hibernation
powercfg /hibernate on

echo Copy startup scripts for disabling FoundNewHardware/DriverSigning wizards
copy c:\vmqa\hw_wizard.vbs ^
	C:\WINDOWS\System32\GroupPolicy\Machine\Scripts\Startup\
copy c:\vmqa\DriverSigning-Off.exe ^
	C:\WINDOWS\System32\GroupPolicy\Machine\Scripts\Startup\

echo Installing VET/STAF etc
cd C:\vmqa
install.bat --api all > vet.log

: FIREWALL_OFF

echo Turning off firewall
reg add HKLM\system\currentcontrolset\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile ^
	/v EnableFirewall /t REG_DWORD /d 0x0 /f

GOTO EXIT

: FIREWALL_ON

echo Turning on firewall
reg add HKLM\system\currentcontrolset\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile ^
	/v EnableFirewall /t REG_DWORD /d 0x1 /f

GOTO EXIT

: EXIT
echo Exiting...
