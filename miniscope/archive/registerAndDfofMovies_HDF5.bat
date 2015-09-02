
:: save current directory
:: set OLDDIR=%CD%
:: the Save HDF5 File plugin only seems to work if you are currently in the ImageJ parent folder when calling imagej from the command-line...don't ask.
:: cd "C:\Program Files\ImageJ"
:: get the DFOF file
:: set /p dfofFile=< %%A\dfof.txt
::
:: jre\bin\javaw.exe -Xmx62000m -Xms62000m -Xincgc -XX:+DisableExplicitGC -XX:+UseCompressedOops -Dplugins.dir="C:\Program Files\ImageJ" -jar "C:\Program Files\ImageJ\ij.jar" -macro saveHDF5File.ijm %dfofFile%

:: chdir /d %OLDDIR% &rem restore current directory
