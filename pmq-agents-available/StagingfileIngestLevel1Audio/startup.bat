Rem /StagingfileIngestLevel1Audio/startup.bat
Rem
Rem Starts the bash convert script to create the level 1 derivative for a Video.

cd %CYGWIN_HOME%\bin
bash.exe -l -c "%scripts%/pmq-agents-available/StagingfileIngestLevel1Audio/startup.sh %*"