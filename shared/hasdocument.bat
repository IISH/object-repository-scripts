call %scripts%\shared\set.bat hasdocument mongo %db% --quiet --eval "var bucket='%bucket%';var pid='%pid%'" %scripts%\shared\hasdocument.js

if "%replaceExistingDerivatives%" == "true" (
    echo Replace existing derivatives
) else (
    if "%hasdocument%" == "true" (
        echo "The file in %bucket% with %pid% exists. Hence we stop processing here."
        exit 245
    )
)