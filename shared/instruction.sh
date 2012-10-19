#
# Starts the instruction manager.
#

scripts=$scripts
JAVA_OPTS=$JAVA_OPTS
pidwebserviceEndpoint=$pidwebserviceEndpoint
pidwebserviceKey=$pidwebserviceKey
manager=$manager
instruction=$instruction

source $scripts/shared/parameters.sh $@

java $JAVA_OPTS -DpidwebserviceEndpoint $pidwebserviceEndpoint -DpidwebserviceKey $pidwebserviceKey -Dmd5sum=md5sum -cp $manager "$instruction"
