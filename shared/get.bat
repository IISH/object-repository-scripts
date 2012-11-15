Rem
Rem Reads a file from the database
Rem

Rem checking params
IF "%pid%"=="" (
    echo missing PID : exiting
    exit -1
)

Rem We skip the get if a file with the same length is already here.
if EXIST "%l%" (
    call %scripts%\shared\set.bat length1 mongo %db% --quiet --eval "Number(db.%sourceBucket%.files.findOne({'metadata.pid':'%pid%'}).length)"
    call %scripts%\shared\set.bat length2 php -r "print(filesize('%l%'));"
    if %length1% == %length2% goto :EOF
)

echo "Get from db=%db% bucket=%sourceBucket% pid=%pid% to %l%"
java -jar %orfiles% -M Get -l "%l%" -h %host% -d "%db%" -b %sourceBucket% -a %pid% -m ""

IF %ERRORLEVEL% NEQ 0 EXIT -1

:EOF