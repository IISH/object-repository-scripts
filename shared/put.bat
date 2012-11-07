Rem  /shared/put.bat
#
# Adds a file into the database
#

    if NOT EXIST "%l%" (
        echo The file does not exist: %l%
        exit -1
    )

if "%derivative%" == "audio" (
    %scripts%\shared\set.bat content ffprobe -v quiet -print_format json -show_format -show_streams "%l%"
)
if "%derivative%" == "video" (
    %scripts%\shared\set.bat content ffprobe -v quiet -print_format json -show_format -show_streams "%l%"
)

    # Prepare a key. We suggest a key based on the shard with the fewest documents.
    set max=2147483647
    set i=0
    set p=0
    for %%s in %secondaries% do (
        set c=0
        %scripts%\shared\set.bat c mongo %%s/%db% --quiet --eval "Math.round(Math.sqrt(db.%bucket%.chunks.dataSize()))"
        if %c% LSS %max% (
           set max=%c%
           set p=%i%
        )
        set /a i=i+1
    )
    %scripts%\shared\set.bat shardKey php %scripts%/shared/shardkey.php -s %i% -p %p%
    echo Shardkey: shard %p% key %shardKey%

    # Upload our file.
    java -jar %orfiles% -c files -l "%l%" -m %md5% -b %bucket% -h %host% -d %db% -a $pid -s $shardKey -t %contentType% -M Put

    set rc=%errorlevel%
    if NOT %rc% == 0 exit %rc%

    mongo %db% --quiet --eval "\
    var access='%access%'; \
    var content=%content%; \
    var filesDB='%db%'; \
    var na='%na%'; \
    var fileSet='%fileSet%'; \
    var label='%label%'; \
    var length=%length%; \
    var md5='%$md5%'; \
    var ns='%bucket%'; \
    var pid='%pid%'; \
    var lid='%lid%'; \
    var resolverBaseUrl='%resolverBaseUrl%'; \
    ''" %scripts%\shared\put.js

    set rc=%errorlevel%
    if NOT %rc% == 0 exit %rc%

    mongo %db% --quiet --eval "\
        var ns='%bucket%'; \
        var md5='%md5%'; \
        var length=%length%; \
        var pid = '%pid%'; \
        ''" %scripts%\shared\integrity.js

    set rc=%errorlevel%
    if NOT %rc% == 0 exit %rc%

    # Add to the statistics
    mongo %db% --quiet --eval "var pid = '%pid%';var ns='%bucket%';" %scripts%\shared\statistics.js

    if "%remove%" == "yes" (
        del "%l%"
        rm "%l%.md5"
        exit 0
    )