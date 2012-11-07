Rem /StagingfileIngestLevel1Video/startup.bat
Rem
Rem The convert script to create the level 1 derivative for a Video

set scripts=%scripts%
call %scripts%\shared\parameters.bat %*
call %scripts%\shared\secondaries.bat

set sourceBucket=master
set targetBucket=level1

Rem Preset 902 = H.264 HD Video (1080p, 16:9)
set preset=902

call %scripts%\shared\video.derivative.bat
exit %errorlevel%