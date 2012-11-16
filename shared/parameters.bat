Rem Set the parameters

:LOOP
    if "%1"=="" goto :NEXT
    set arg=%1
    IF "%arg:~0,1%" == "-" (
        set key=%arg:~1%
        set value=%2
	    set %key%=%value%
	    shift
    )
    shift
goto :LOOP
:NEXT

IF not defined na (
    echo NA is not set.
    EXIT -1
)

set db=or_%na%

set label=empty

if EXIST "%l%" (
    call %scripts%\shared\set.bat length php -r "print(filesize('%l%'));"
)


