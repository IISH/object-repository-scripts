Rem Reads a file from the database.collection and removes it.

if NOT "%action%" == "delete" goto :EOF

    call %scripts%\shared\set.bat files_id mongo %db% --quiet --eval "var doc=db.%bucket%.files.findOne({'metadata.pid':'%pid%'}, {_id:1});if ( doc ){print(doc._id)}"
    if not defined files_id (
        echo PID %pid% not in database.
        exit 245
    )

    mongo %db% --quiet --eval "db.%bucket%.files.remove({_id:%files_id%})"
    mongo %db% --quiet --eval "db.%bucket%.chunks.remove({files_id:%files_id%})"

    Rem Verify our removal
    call %scripts%\shared\set.bat count mongo %db% --quiet --eval "db.%bucket%.files.count({_id:%files_id%})"
    if %count% NEQ 0 (
        echo Failed to delete document %pid% from files.%bucket%
        exit -1
    )

    call %scripts%\shared\set.bat count mongo %db% --quiet --eval "db.%bucket%.chunks.count({files_id:%files_id%})"
    if %count% NEQ 0 (
        echo Failed to delete document %pid% from chunks.%bucket%
        exit -1
    )

    echo Document %pid% removed from %bucket%
    exit 0

:EOF