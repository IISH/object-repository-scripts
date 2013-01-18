Rem  /shared/put.bat
Rem
Rem Adds a file into the database
Rem

    if NOT EXIST "%l%" (
        echo The file does not exist: %l%
        exit -1
    )

    call %scripts%\shared\set.bat dependencies php -r "print( str_replace('\\','\\\\', '%scripts%\shared\randomseed.js') );"
    call %scripts%\shared\set.bat shardKey mongo %db% --quiet --eval "var dependencies='%dependencies%'; var bucket='%bucket%'; var shards=%shards%" %scripts%\shared\shardkey.js
    call %scripts%\shared\set.bat is_numeric php -r "print(is_numeric('%shardKey%'));"
    if NOT DEFINED is_numeric (
        set shardKey=0
    )

    if %shardKey% == 0 (
        echo Could not retrieve a shardkey. Primaries may be down.
        exit -1
    )

    Rem Upload our file.
    java -DWriteConcern=FSYNC_SAFE -jar %orfiles% -c files -l "%l%" -m %md5% -b %bucket% -h %host% -d %db% -a %pid% -t %contentType% -s %shardKey% -M Put

    set rc=%errorlevel%
    if %rc% neq 0 exit %rc%

    Rem assemble a batch script for the metadata update:
    set batch=%temp%\%identifier%.content.bat
    echo set content=>%batch%
    ffprobe -v quiet -print_format json -show_format -show_streams "%l%">>%batch%
    php %scripts%\shared\wrapper.php -i %batch% -o %batch%
    echo ;>>%batch%
    echo mongo %db% --quiet --eval "var access='%access%'; var content=%%content%%;var filesDB='%db%'; var na='%na%'; var fileSet='%fileSet%'; var label='%label%'; var length=%length%; var md5='%md5%'; var ns='%bucket%'; var pid='%pid%'; var lid='%lid%'; var resolverBaseUrl='%resolverBaseUrl%'; var contentType='%contentType%';" %scripts%\shared\put.js>>%batch%
    call %batch%
    del %batch%

    set rc=%errorlevel%
    if NOT %rc% == 0 exit %rc%

    mongo %db% --quiet --eval "var ns='%bucket%'; var md5='%md5%'; var length=%length%; var pid = '%pid%';" %scripts%\shared\integrity.js

    set rc=%errorlevel%
    if %rc% neq 0 exit %rc%

    del "%l%"
    del "%l%.md5"
    exit 0