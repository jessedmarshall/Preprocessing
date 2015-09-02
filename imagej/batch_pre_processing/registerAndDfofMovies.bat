:: biafra ahanonu
:: created: 2013.09.13 [03:20:37]-ish
:: wrapper to call imagej plugin, clear RAM, etc.
:: changelog
    :: updated: 2013.09.19 [10:56:28] added the ability for the script to handle error signals from java
    :: updated: 2013.10.23 [20:43:29] more commenting of each line
    :: 2014.01.11 [14:43:02] english...

@echo off
setlocal enabledelayedexpansion

::default text file containing directories to analyze
set analysisDir=../analyze/p104_m747_imagej146.txt
::ask user for directory
::set /p analysisDir=donde estas el archivo?
set /p analysisDir=input location of the analysis paths text file:

:: go line-by-line in file, get directories to analyze
for /F "tokens=*" %%A in (%analysisDir%) do (
    echo %%A
    :: call imagej (using 32-bit pointers), pass along directory
    javaw -Xmx62000m -Xms62000m -Xincgc -XX:+DisableExplicitGC -XX:+UseCompressedOops -Dplugins.dir="D:\programs\ImageJ" -jar "D:\programs\ImageJ\ij.jar" -macro registerFiles.ijm %%A

    ::check the exit status
    echo %errorlevel%
    if errorlevel 4 call :WTF
    if errorlevel 3 call :MISSINGFILES
    if errorlevel 2 call :FOLDERERROR
    if errorlevel 1 call :TIFFERROR
    if errorlevel 0 call :SUCCESS

    echo ---------------------
)
:: error handling
exit /b
::not all errors are captured, so sometimes things fail spectacularly
:WTF
    echo i don't know what went wrong.
    goto ENDLOOP
::there are no tif files in the folder given
:MISSINGFILES
    echo what's a folder without files!?
    goto ENDLOOP
::if have too many folders from previous runs, should be eliminated from plugin
:FOLDERERROR
    echo stop being a bureaucrat, clean-up your folders!
    goto ENDLOOP
:: if the target.tif is missing, run mm_make_targets_1 beforehand
:TIFFERROR
    echo don't have a target.tif!
    goto ENDLOOP
::ostensibly everything went well...
:SUCCESS
    echo AMERICA!
    goto ENDLOOP
::return to the loop
:ENDLOOP
exit /b