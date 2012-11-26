Rem /StagingfileIngestLevel1Video/startup.bat
Rem
Rem The convert script to create the level 1 derivative for a Video

set scripts=%scripts%
call %scripts%\shared\parameters.bat %*

set sourceBucket=master
set bucket=level1

call %scripts%\shared\delete.bat
call %scripts%\shared\hasdocument.bat

Rem Preset 4169 = H.264 AAC ; same framerate as input
set preset=4169
set targetContentType=video/mp4
set derivative=video
set format=mp4

call %scripts%\shared\av.derivative.bat
exit %errorlevel%