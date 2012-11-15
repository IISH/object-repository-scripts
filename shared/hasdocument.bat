call %scripts%\shared\set.bat hasdocument mongo %db% --quiet --eval "var bucket='%targetBucket%';var pid='%pid%'" %scripts%\shared\hasdocument.js
if "%hasdocument%" == "true" (
    echo "The file in %targetBucket% with %pid% exists. Hence we stop processing here."
    exit 245
)