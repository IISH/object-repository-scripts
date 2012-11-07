Rem /shared/secondaries.bat
Rem
Rem
Rem ensures the MongoDB secondaries are those servers we expect them to be.

for %%s in %secondaries% do (
    set issecondary=false
    %scripts%\shared\set.bat issecondary mongo %%s --quiet --eval "db.serverStatus().repl.issecondary"
    if NOT "%issecondary%" == "true" (
        echo %%s is not secondary; issecondary=%issecondary%
        Rem exit -1
    )
)

