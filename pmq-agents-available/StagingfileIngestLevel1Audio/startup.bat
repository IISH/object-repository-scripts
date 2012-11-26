Rem /StagingfileIngestLevel1Audio/startup.bat
Rem
Rem The convert script to create the level 1 derivative for an Audio

set scripts=%scripts%
call %scripts%\shared\parameters.bat %*

set sourceBucket=master
set bucket=level1

call %scripts%\shared\delete.bat
call %scripts%\shared\hasdocument.bat

Rem Preset 120 = Audio Only: MP3 High Quality
set preset=120
set targetContentType=audio/mp3
set derivative=audio
set format=mp3

call %scripts%\shared\av.derivative.bat
exit %errorlevel%