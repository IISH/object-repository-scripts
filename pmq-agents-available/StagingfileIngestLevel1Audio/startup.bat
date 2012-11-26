Rem /StagingfileIngestLevel1Audio/startup.bat
Rem
Rem The convert script to create the level 1 derivative for an Audio

set scripts=%scripts%
call %scripts%\shared\parameters.bat %*

set sourceBucket=master
set targetBucket=level1

call %scripts%\shared\delete.bat
call %scripts%\shared\hasdocument.bat

Rem Preset 211 = Audio Only: AAC Good Quality
Rem set preset=211
Rem set targetContentType=audio/mp4
Rem set derivative=audio
Rem set format=m4a

call %scripts%\shared\av.derivative.bat
exit %errorlevel%