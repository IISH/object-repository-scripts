Rem Reads a file from the database.collection and removes it.

if NOT "%action%" == "delete" goto :EOF

    call %scripts%\shared\set.bat files_id mongo %db% --quiet --eval "var doc=db.%targetBucket%.files.findOne({'metadata.pid':'%pid%'}, {_id:1});if ( doc ){print(doc._id)}"
    if not defined files_id (
        echo PID %pid% not in database.
        exit 245
    )

    mongo %db% --quiet --eval "db.%targetBucket%.files.remove({_id:%files_id%})"
    mongo %db% --quiet --eval "db.%targetBucket%.chunks.remove({files_id:%files_id%})"

    Rem Verify our removal
    call %scripts%\shared\set.bat count mongo %db% --quiet --eval "db.%targetBucket%.files.count({_id:%files_id%})"
    if %count% NEQ 0 (
        echo Failed to delete document %pid% from files.%targetBucket%
        exit -1
    )

    call %scripts%\shared\set.bat count mongo %db% --quiet --eval "db.%targetBucket%.chunks.count({files_id:%files_id%})"
    if %count% NEQ 0 (
        echo Failed to delete document %pid% from chunks.%targetBucket%
        exit -1
    )

    echo Document %pid% removed from %targetBucket%
    exit 0

:EOF