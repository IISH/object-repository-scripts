#
# Starts the instruction manager.
#
source $scripts/shared/parameters.sh $@

java $JAVA_OPTS -Dmd5sum=md5sum -cp $manager "$instruction"
