Rem /shared/video.derivative.bat
Rem
Rem Retrieve the source file and make a derivative
set tmp=%derivative_cache%
set targetFile=%tmp%\%md5%.%targetBucket%

    set l=%tmp%\%md5%.%sourceBucket%
    del %l%
    call %scripts%\shared\get.bat

:NEXT
if EXIST %l% (
    mvccl /file %l% /outputfile %targetFile% /preset %preset% /cuda /multicore /overwrite /progress
    set rc=%errorlevel%
    if %rc% ==  1 echo The program has been compromised. | EXIT %rc%
    if %rc% ==  2 echo No such file or directory. | EXIT %rc%
    if %rc% ==  3 echo Internal error. | EXIT %rc%
    if %rc% ==  4 echo The preset has not been found. | EXIT %rc%
    if %rc% ==  5 echo I/O error. | EXIT %rc%
    if %rc% == 12 echo Not enough memory. | EXIT %rc%
    if %rc% == 22 echo Invalid argument. | EXIT %rc%
    if %rc% == 28 echo No enough space on the hard drive. | EXIT %rc%
    if %rc% == 29 echo Conversion error. | EXIT %rc%
    if %rc% == 30 echo Invalid conversion settings. | EXIT %rc%
    if %rc% == 31 echo The conversion has been interrupted by the user. | EXIT %rc%
    if %rc% == 32 echo The trial period has been expired. | EXIT %rc%
    if %rc% == 33 echo Copy-protected DVD. | EXIT %rc%
) else (
    echo "Could not find a master or higher level derivative to produce a %targetBucket% file"
    echo "We need at least master to produce a derivative."
    exit 240
)

del %l%

if EXIST %targetFile% (
	set contentType=video/mp4
	l=%targetFile%
	%scripts%\shared\set.bat md5 java -cp %orfiles% org.objectrepository.util.Checksum "%l%" --arg
	echo %md5% %$targetFile% > %targetFile%.md5
	set remove=yes
	set derivative=video
	%scripts%\shared\put.bat
) else (
	echo "Unable to create derivative."
	exit 240
)