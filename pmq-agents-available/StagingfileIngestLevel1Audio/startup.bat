Rem /StagingfileIngestLevel1Audio/startup.bat
Rem
Rem The convert script to create the level 1 derivative for an Audio

set scripts=%scripts%
call %scripts%\shared\parameters.bat %*
call %scripts%\shared\secondaries.bat

set sourceBucket=master
set targetBucket=level1

Rem Preset 119 = Audio Only: MP3 Good Quality
set preset=119

call %scripts%\shared\video.derivative.bat
exit %errorlevel%