Rem /StagingfileIngestLevel1Video/startup.bat
Rem
Rem The convert script to create the level 1 derivative for a Video

cd %CYGWIN_HOME%\bin
bash.exe -l -c "%scripts%/pmq-agents-available/StagingfileIngestLevel1Video/startup.sh %*"