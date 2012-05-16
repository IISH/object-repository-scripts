#!/bin/bash
#
# /shared/success.sh
#
# Updates the workflow status
#

mongo sa --quiet --eval "var fileSet='$fileSet'; var id='$id'; var name='$name';''" $scripts/shared/success.js
