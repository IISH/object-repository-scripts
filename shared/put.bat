Rem  /shared/put.bat
Rem
Rem Adds a file into the database
Rem

    if NOT EXIST "%l%" (
        echo The file does not exist: %l%
        exit -1
    )

    Rem Upload our file.
    java -jar %orfiles% -c files -l "%l%" -m %md5% -b %bucket% -h %host% -d %db% -a %pid% -t %contentType% -M Put

    set rc=%errorlevel%
    if %rc% neq 0 exit %rc%

    set batch=%temp%\%identifier%.content.bat
    echo set content=>%batch%
    ffprobe -v quiet -print_format json -show_format -show_streams "%l%">>%batch%
    php %scripts%\shared\wrapper.php -i %batch% -o %batch%
    echo ;>>%batch%
    echo mongo %db% --quiet --eval "var access='%access%'; var content=%%content%%;var filesDB='%db%'; var na='%na%'; var fileSet='%fileSet%'; var label='%label%'; var length=%length%; var md5='%md5%'; var ns='%bucket%'; var pid='%pid%'; var lid='%lid%'; var resolverBaseUrl='%resolverBaseUrl%'" %scripts%\shared\put.js>>%batch%
    call %batch%
    del %batch%

    set rc=%errorlevel%
    if NOT %rc% == 0 exit %rc%

    mongo %db% --quiet --eval "var ns='%bucket%'; var md5='%md5%'; var length=%length%; var pid = '%pid%'; ''" %scripts%\shared\integrity.js

    set rc=%errorlevel%
    if %rc% neq 0 exit %rc%

    Rem Add to the statistics
    Rem mongo %db% --quiet --eval "var pid = '%pid%';var ns='%bucket%';" %scripts%\shared\statistics.js

        del "%l%"
        rm "%l%.md5"
        exit 0