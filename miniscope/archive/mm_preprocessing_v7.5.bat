::biafra ahanonu
:: created: 2013.09.13 [03:20:37]-ish
::wrapper to call imagej plugin, clear RAM, etc.

@echo off
setlocal enabledelayedexpansion

::
for /F "tokens=*" %%A in (mm_preprocessing_v7.5.directories.txt) do (
    echo %%A
    javaw -Xmx62000m -Xms62000m -Xincgc -XX:+DisableExplicitGC -XX:+UseCompressedOops -Dplugins.dir="C:\Program Files\ImageJ" -jar "C:\Program Files\ImageJ\ij.jar" -macro mm_preprocessing_v7.5.ijm %%A
)

::set  arrayline[0]=E:\biafra\data\miniscope\pav\p92\2013_08_24_p92_m816_MAG3\
::set  arrayline[1]=E:\biafra\data\miniscope\check\hd_a\2013_08_23_m473\concat\
::call array.bat len arrayline length

::for /l %%n in (0,1,%length%) do (
::    echo !arrayline[%%n]!
::    javaw -Xmx62000m -Xms62000m -Xincgc -XX:+DisableExplicitGC -XX:+UseCompressedOops -Dplugins.dir="C:\Program Files\ImageJ" -jar "C:\Program Files\ImageJ\ij.jar" -macro registerFiles.ijm !arrayline[%%n]!
::)

::java -Dplugins.dir="C:\Program Files\ImageJ" -jar "C:\Program Files\ImageJ\ij.jar" -macro registerFiles.txt E:\biafra\data\miniscope\check\hd_a\2013_09_12_m475\concat\