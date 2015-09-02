::Jakash3
::updated: 2013.09.12 [22:25:56]
::biafra ahanonu
::http://jakash3.wordpress.com/2009/12/18/arrays-in-batch/

@echo off

set array.return=goto :eof
set array.func=%1
set array.func.args=%2 %3 %4 %5 %6 %7 %8 %9
call :%array.func% %array.func.args%
goto :eof


:add
REM Adds a new item at the end of an array
REM Arguments: (
REM name As "Array Name",
REM value As "New value"
REM )
set array.name=%1
set array.value=%2
for /f "delims=[=] tokens=1,2,3" %%a in ('set %array.name%[') do (
set array.index=%%b
)
set /a array.index+=1
set %array.name%[%array.index%]=%array.value%
goto :eof


:len
REM Gets array length.
REM Arguments: (
REM name As "Array name"
REM var As "Output Variable"
REM )
set array.name=%1
set array.var=%2
for /f "delims=[=] tokens=2" %%a in ('set %array.name%[') do (
set %array.var%=%%a
)
goto :eof


:getitem
REM Get value of index in array.
REM Arguments: (
REM name As "Array Name",
REM index As "Item Index",
REM var As "Output Variable"
REM )
set array.name=%1
set array.index=%2
set array.var=%3
for /f "delims=[=] tokens=1,2,3" %%a in ('set %array.name%[') do (
if %%b==%array.index% set %array.var%=%%c
)
goto :eof