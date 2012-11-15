Rem
Rem Reads a file from the database
Rem

Rem checking params
IF "%pid%"=="" (
    echo missing PID : exiting
    exit -1
)

echo "Get from db=%db% bucket=%sourceBucket% pid=%pid% to %l%"
java -jar %orfiles% -M Get -l "%l%" -h %host% -d "%db%" -b %sourceBucket% -a %pid% -m ""

IF %ERRORLEVEL% NEQ 0 EXIT -1

:EOF