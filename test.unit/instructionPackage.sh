#!/bin/bash
#
# unit test voor
# /InstructionPackage/startup.sh


fileSet="$1" # substitute as necessary. Be careful, because the procedure will remove this directory after a rar.
if [ -z "$fileSet" ]
then
    echo "Need a fileSet. Be careful, because the procedure will remove this directory after a successful rar."
    exit 1
fi

this_parent=$(dirname "${0}")
scripts=$(dirname "${this_parent}")

echo "Running ${scripts}/pmq-agents-available/InstructionPackage/startup.sh"
source "${scripts}/pmq-agents-available/InstructionPackage/startup.sh" -access "open" -fileSet "$fileSet" -na "12345" -sa_path /tmp
