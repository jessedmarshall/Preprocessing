:: biafra ahanonu
:: updated: 2013.11.08 [20:27:43]
:: save a particular file as a bat

::javaw -Xmx62000m -Xms62000m -Xincgc -XX:+DisableExplicitGC -XX:+UseCompressedOops -Dplugins.dir="C:\Program Files\ImageJ" -jar "C:\Program Files\ImageJ\ij.jar" -macro saveHDF5File.ijm A:\shared\00_normalized_recording_20130929_213357.tif


set OLDDIR=%CD%

cd "C:\Program Files\ImageJ"
jre\bin\javaw.exe -Xmx62000m -Xms62000m -Xincgc -XX:+DisableExplicitGC -XX:+UseCompressedOops -Dplugins.dir="C:\Program Files\ImageJ" -jar "C:\Program Files\ImageJ\ij.jar" -macro saveHDF5File.ijm A:\shared\00_normalized_recording_20130926_102740.tif

chdir /d %OLDDIR% &rem restore current directory