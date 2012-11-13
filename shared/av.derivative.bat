Rem /shared/video.derivative.bat
Rem
Rem Retrieve the source file and make a derivative
set tmp=%derivative_cache%
set targetFile=%tmp%\%md5%.%targetBucket%

    set l=%tmp%\%md5%.%sourceBucket%
    if EXIST "%l%" del %l%
    call %scripts%\shared\get.bat
    rem copy /y "%l%.bk" "%l%"

if NOT EXIST "%l%" (
    echo Could not find a master or higher level derivative to produce a %targetBucket% file.
    echo We need at least master to produce a derivative.
    EXIT 240
)

mvccl /file "%l%" /outputfile "%targetFile%" /preset %preset% %mvccl_opts%
rem copy /y "%targetFile%.bk" "%targetFile%"

set rc=%errorlevel%
if %rc% == 1 echo The program has been compromised. & EXIT -1
if %rc% == 2 echo No such file or directory. & EXIT -1
if %rc% == 3 echo Internal error. & EXIT -1
if %rc% == 4 echo The preset has not been found. & EXIT -1
if %rc% == 5 echo I/O error. & EXIT -1
if %rc% == 12 echo Not enough memory. & EXIT -1
if %rc% == 22 echo Invalid argument. & EXIT -1
if %rc% == 28 echo No enough space on the hard drive. & EXIT -1
if %rc% == 29 (
    echo Conversion error.
    echo Fall back on ffmpeg
    ffmpeg -i "%l%" -vcodec libx264 -preset slower -crf 23 "%targetFile%"
)
if %rc% == 30 echo Invalid conversion settings. & EXIT -1
if %rc% == 31 echo The conversion has been interrupted by the user. & EXIT -1
if %rc% == 32 echo The trial period has been expired. & EXIT -1
if %rc% == 33 echo Copy-protected DVD. & EXIT -1

del %l%

if NOT EXIST "%targetFile%" (
    echo Unable to create derivative.
	exit 240
)

set contentType=%targetContentType%
set l=%targetFile%
call %scripts%\shared\set.bat md5 java -cp %orfiles% org.objectrepository.util.Checksum "%l%" --arg
echo %md5% %targetFile% > %targetFile%.md5
call %scripts%\shared\set.bat length php -r "print(filesize('%l%'));"
set bucket=%targetBucket%
call %scripts%\shared\put.bat