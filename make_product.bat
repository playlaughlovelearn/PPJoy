:: @echo off 

pushd .

setlocal enableextensions enabledelayedexpansion

:: Set to the name of the sub-directories for the output files
set OutputRoot=___Product___
set SupportPath=___Support___


set ReleaseDir=%OutputRoot%\Release
set DebugDir=%OutputRoot%\Debug

set ReleaseSupport=%ReleaseDir%\%SupportPath%
set DebugSupport=%DebugDir%\%SupportPath%

:: set PPJoyDevRoot to the location of this batch file
set PPJoyDevRoot=%~dp0

echo Building PPJoy...

:: ============ Build options for customised PPJoy setup =======================
:: :: SET INSTALLBAT=PPJoy.bat
:: :: SET PPJOYZIP=PPJoySetup.zip
:: =============================================================================

:: ============ Compiler config ==============================
set DdkMajor=7600
set DdkMinor=16385
set DdkRev=1
set DdkFullPath=G:\WinDDK\%DdkMajor%.%DdkMinor%.%DdkRev%

set VisualStudioExe="%VisualStudioExeDir%devenv.exe"
:: set VisualStudioExeDir=C:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\IDE	
:: set VSE2005ROOT=C:\Program Files (x86)\Microsoft Visual Studio 8\Common7\IDE
:: set VSE2005CMD=VCExpress.exe
:: ===========================================================

echo.
echo Starting build process
echo ======================
echo.

cd /d %PPJoyDevRoot%

:: NO! NO! NO! NO! NO! NO! and NO!
::
:: before removing a directory with a command like rmdir /s /q (all subdirs, QUIET)
:: you better be gosh-darned sure that you got a directory called that. oh yeah; BTW
:: whatever the issues is caused it to completely delete my entire PPJoy Directory,
:: including .git so i could have been completely screwed had i not already pushed
:: to github.
::
:: rmdir /s /Q "%PPJoyDevRoot%%ReleaseDir%"
:: rmdir /s /Q "%PPJoyDevRoot%%DebugDir%"

:: no reason to make directories other than the lowest level since they will all get made
:: mkdir "%PPJoyDevRoot%%ReleaseDir%
:: mkdir "%PPJoyDevRoot%%DebugDir%"

mkdir "%PPJoyDevRoot%%ReleaseSupport%"
mkdir "%PPJoyDevRoot%%DebugSupport%"

echo DDK Path: %DdkFullPath%

:: NO! NO! NO! NO! NO! NO! and NO! BAD DEVELOPER NO COFFEE!
::
:: rmdir /s /Q "%PPJoyDevRoot%\Scripts"

mkdir "%PPJoyDevRoot%\Scripts"

echo.
echo =================================================================================
echo   Building PPJoy drivers for all platforms...
echo --------------------------------------------------------------------------------
echo.

echo Building checked (debug) version of PPJoy drivers...

setlocal
call "%DdkFullPath%\bin\setenv.bat" %DdkFullPath% chk wxp
cd /D "%PPJoyDevRoot%"
build /c
endlocal

echo Building free (release) version of PPJoy drivers...

setlocal
call "%DdkFullPath%\bin\setenv.bat" %DdkFullPath% fre wxp
cd /D "%PPJoyDevRoot%"
build /c
endlocal

echo Building checked (debug) 64 bit version of PPJoy drivers...

setlocal
call "%DdkFullPath%\bin\setenv.bat" %DdkFullPath% chk x64 WLH
cd /D "%PPJoyDevRoot%"
build /c
endlocal

echo Building free (release) 64 bit version of PPJoy drivers...

setlocal
call "%DdkFullPath%\bin\setenv.bat" %DdkFullPath% fre x64 WLH
cd /D "%PPJoyDevRoot%"
build /c
endlocal

:: echo.
:: echo ==================================================
:: echo   Building setup helper plugin (legacy platform)
:: echo ==================================================
:: echo.

:: cd /D "%PPJoyDevRoot%\SetupHelper"
:: "%VSE2005ROOT%\%VSE2005CMD%" SetupHelper.sln /rebuild "Debug|Win32"
:: "%VSE2005ROOT%\%VSE2005CMD%" SetupHelper.sln /rebuild "Release|Win32"

:: output is only in Buildlog.html - make plan later

setlocal

:: Set env variables for command line compiler - will use in some cases
call "%VisualStudioExeDir%"..\..\..\VC\bin\vcvars32.bat
set INCLUDE=%INCLUDE%;"%DdkFullPath%\inc\api

:: for some strange reason the wxp directory is missing the dxguid.lib library so we tack the Win 2003 srv dir on to the end.
set LIB=%LIB%;"%DdkFullPath%\lib\wxp\i386;"%DdkFullPath%\lib\wnet\i386

set x86compiler=
set amd64compiler=

if %PROCESSOR_ARCHITECTURE%==X86 (
	set CC_X86=x86
	set CC_AMD64=x86_amd64
) else (
	if %PROCESSOR_ARCHITECTURE%==AMD64 (
		set CC_X86=amd64_x86
		set CC_AMD64=amd64
	) else (
		goto :NO_ARCH
	)
)

echo.
echo.
echo =================================================================================
echo  PPJoy Full Product Build
echo =================================================================================
echo.
echo.
echo =================================================================================
echo  + START Building Projects 
echo --------------------------------------------------------------------------------
echo running %VcInstallDir%\VcVarsAll.bat %CC_X86% 

cd /d "%VcInstallDir%"

:: Setup for x86 (actual win32, not 'win32') Builds
setlocal
cd /d "%VcInstallDir%"
call "%VcVarsAll% %CC_X86%"

echo Creating additional script files...
cd /D "%PPJoyDevRoot%\CreateBAT"
"%VisualStudioExe%" CreateBAT.sln /rebuild "Release|Win32" /UseEnv
cd /D "%PPJoyDevRoot%\Scripts"
"%PPJoyDevRoot%\CreateBAT\Release\CreateBAT"

echo Creating Device Driver INF Files ... 
cd /D "%PPJoyDevRoot%\CreateINF"
"%VisualStudioExe%" CreateINF.sln /rebuild "Release|Win32" /UseEnv
cd /D "%PPJoyDevRoot%\%ReleaseDir%"
"%PPJoyDevRoot%\CreateINF\Release\CreateINF"
cd /D "%PPJoyDevRoot%\%DebugDir%
"%PPJoyDevRoot%\CreateINF\Release\CreateINF"

echo Building AddJoyDrivers helper dll...
cd /D "%PPJoyDevRoot%\AddJoyDrivers"
"%VisualStudioExe%" AddJoyDrivers.sln /rebuild "Debug|Win32" /UseEnv
"%VisualStudioExe%" AddJoyDrivers.sln /rebuild "Release|Win32" /UseEnv
endlocal

:: Setup for AMD64 Builds 

setlocal
cd /d "%VcInstallDir%"
call "%VcVarsAll% %CC_AMD64%"

echo Building Helper64 x64 helper...
cd /D "%PPJoyDevRoot%\Helper64"
"%VisualStudioExe%" Helper64.sln /rebuild "Debug|x64" /UseEnv
"%VisualStudioExe%" Helper64.sln /rebuild "Release|x64" /UseEnv

echo Building UnInst64 x64 helper...
cd /D "%PPJoyDevRoot%\UnInst64"
"%VisualStudioExe%" UnInst64.sln /rebuild "Debug|x64" /UseEnv
"%VisualStudioExe%" UnInst64.sln /rebuild "Release|x64" /UseEnv
endlocal

:: Setup for x86 (actual win32, not 'win32') Builds
setlocal
cd /d "%VcInstallDir%"
call "%VcVarsAll% %CC_X86%"

echo Building ViseHelper helper dll...
cd /D "%PPJoyDevRoot%\ViseHelper"
"%VisualStudioExe%" ViseHelper.sln /rebuild "Debug|Win32" /UseEnv
"%VisualStudioExe%" ViseHelper.sln /rebuild "Release|Win32" /UseEnv

echo Building PPJoyAPI library...
cd /D "%PPJoyDevRoot%\PPJoyAPI"
"%VisualStudioExe%" PPJoyAPI.sln /rebuild "Debug|Win32" /UseEnv
"%VisualStudioExe%" PPJoyAPI.sln /rebuild "Release|Win32" /UseEnv

echo Building IOCTLSample test application...
cd /D "%PPJoyDevRoot%\IOCTLSample"
copy /y "%PPJoyDevRoot%\Scripts\ppjioctl_devname.h"
"%VisualStudioExe%" IOCTLSample.sln /rebuild "Release|Win32" /UseEnv

echo Building PPJoy Control Panel application...
cd /D "%PPJoyDevRoot%\PPJoyCpl"
"%VisualStudioExe%" PPJoyCpl.sln /rebuild "Debug|Win32" /UseEnv
"%VisualStudioExe%" PPJoyCpl.sln /rebuild "Release|Win32" /UseEnv

echo Building PPJoyCOM application...
cd /D "%PPJoyDevRoot%\PPJoyCOM"
"%VisualStudioExe%" PPJoyCOM.sln /rebuild "Debug|Win32" /UseEnv
"%VisualStudioExe%" PPJoyCOM.sln /rebuild "Release|Win32" /UseEnv

echo Building PPJoyDLL application...
cd /D "%PPJoyDevRoot%\PPJoyDLL"
"%VisualStudioExe%" PPJoyDLL.sln /rebuild "Debug|Win32" /UseEnv
"%VisualStudioExe%" PPJoyDLL.sln /rebuild "Release|Win32" /UseEnv

echo Building PPJoyJoy application...
cd /D "%PPJoyDevRoot%\PPJoyJoy"
"%VisualStudioExe%" PPJoyJoy.sln /rebuild "Debug|Win32" /UseEnv
"%VisualStudioExe%" PPJoyJoy.sln /rebuild "Release|Win32" /UseEnv

echo Building PPJoyKey application...
cd /D "%PPJoyDevRoot%\PPJoyKey"
"%VisualStudioExe%" PPJoyKey.sln /rebuild "Debug|Win32" /UseEnv
"%VisualStudioExe%" PPJoyKey.sln /rebuild "Release|Win32" /UseEnv

echo Building PPJoyMouse application...
cd /D "%PPJoyDevRoot%\PPJoyMouse"
"%VisualStudioExe%" PPJoyMouse.sln /rebuild "Debug|Win32" /UseEnv
"%VisualStudioExe%" PPJoyMouse.sln /rebuild "Release|Win32" /UseEnv

echo Building input .DLLs for PPJoyDLL...
cd /D "%PPJoyDevRoot%\RCCallbackDLLs"
"%VisualStudioExe%" RCCallbackDLLs.sln /rebuild "Debug Futaba_PCM|Win32" /UseEnv
"%VisualStudioExe%" RCCallbackDLLs.sln /rebuild "Debug Futaba_PPM|Win32" /UseEnv
"%VisualStudioExe%" RCCallbackDLLs.sln /rebuild "Debug JR_PCM|Win32" /UseEnv
"%VisualStudioExe%" RCCallbackDLLs.sln /rebuild "Debug JR_PPM|Win32" /UseEnv
"%VisualStudioExe%" RCCallbackDLLs.sln /rebuild "Release Futaba_PCM|Win32" /UseEnv
"%VisualStudioExe%" RCCallbackDLLs.sln /rebuild "Release Futaba_PPM|Win32" /UseEnv
"%VisualStudioExe%" RCCallbackDLLs.sln /rebuild "Release JR_PCM|Win32" /UseEnv
"%VisualStudioExe%" RCCallbackDLLs.sln /rebuild "Release JR_PPM|Win32" /UseEnv

endlocal

echo --------------------------------------------------------------------------------
echo  - FINISH Building Projects
echo =================================================================================

echo.
echo =================================================================================
echo Copying compiled files to product directory...
echo --------------------------------------------------------------------------------
echo.

cd /D "%PPJoyDevRoot%"
call Scripts\CopyProducts.bat %ReleaseDir% %DebugDir%
:: use for test certificate in an PFX exported file. DO NOT EXPORT real certificate to a PFX file
call Scripts\SignDriverFiles.bat %DdkFullPath% /f TestSign\TestCertificate.pfx %ReleaseDir% %DebugDir%
REM
:: For real certificates use:
:: call Scripts\SignDriverFiles.bat %DdkFullPath% /s <CertStoreName> %ReleaseDir% %DebugDir%
REM

@echo on

copy /y IOCTLSample\Release\IOCTLSample.exe %ReleaseSupport%
copy /y IOCTLSample\Release\IOCTLSample.exe %DebugSupport%
copy /y AddJoyDrivers\Release\AddJoyDrivers.dll %ReleaseSupport%
copy /y AddJoyDrivers\Debug\AddJoyDrivers.dll %DebugSupport%
copy /y ViseHelper\Release\ViseHelper.dll %ReleaseSupport%
copy /y ViseHelper\Debug\ViseHelper.dll %DebugSupport%
copy /y SetupHelper\Release\SetupHelper.dll %ReleaseSupport%
copy /y SetupHelper\Debug\SetupHelper.dll %DebugSupport%
copy /y Helper64\x64\Release\Helper64.exe %ReleaseSupport%
copy /y Helper64\x64\Debug\Helper64.exe %DebugSupport%
copy /y UnInst64\x64\Release\UnInst64.exe %ReleaseSupport%
copy /y UnInst64\x64\Debug\UnInst64.exe %DebugSupport%
copy /y PPJoyAPI\Release\PPJoyAPI.lib %ReleaseSupport%
copy /y PPJoyAPI\Debug\PPJoyAPI.lib %DebugSupport%
copy /y PPJoyAPI\PPJoyAPI.h %ReleaseSupport%
copy /y Tools\AddDriversTest\AddDriversTest.c %ReleaseSupport%

copy /y PPJoyCOM\Release\PPJoyCOM.exe %ReleaseDir%
copy /y PPJoyCOM\Debug\PPJoyCOM.exe %DebugDir%
copy /y PPJoyDLL\Release\PPJoyDLL.exe %ReleaseDir%
copy /y PPJoyDLL\Debug\PPJoyDLL.exe %DebugDir%

copy /y PPJoyJoy\Release\PPJoyJoy.exe %ReleaseDir%
copy /y PPJoyJoy\Debug\PPJoyJoy.exe %DebugDir%
copy /y PPJoyKey\Release\PPJoyKey.exe %ReleaseDir%
copy /y PPJoyKey\Debug\PPJoyKey.exe %DebugDir%

copy /y PPJoyMouse\Release\PPJoyMouse.exe %ReleaseDir%
copy /y PPJoyMouse\Debug\PPJoyMouse.exe %DebugDir%

copy /y RCCallbackDLLs\Release\*.dll %ReleaseDir%
copy /y RCCallbackDLLs\Debug\*.dll %DebugDir%

zip -9 -X -j %PPJoyDevRoot%\Docs\Diagrams\Virtual\IOCTLSample.zip %PPJoyDevRoot%\IOCTLSample\*
zip -9 -X -j %PPJoyDevRoot%\Docs\Diagrams\Virtual\RCCallbackDLLs.zip %PPJoyDevRoot%\RCCallbackDLLs\*

xcopy /s /i docs %ReleaseDir%\docs

@echo off

echo --------------------------------------------------------------------------------
echo Done.
echo =================================================================================

echo.
echo =================================================================================
echo  Building PPJoyInstaller...
echo --------------------------------------------------------------------------------
echo.

"C:\Program Files (x86)\NSIS\makensis.exe" Installer\PPJoyInstaller.nsi

echo --------------------------------------------------------------------------------
echo  Installer Build complete.
echo =================================================================================

echo.
echo Project and installation build complete.
echo.

endlocal

:NO_ARCH
echo. ERROR: No PROCESSOR_ARCHITECTURE was found! Are you running under a Visual Studio Developer CMD?

:EOF

popd
