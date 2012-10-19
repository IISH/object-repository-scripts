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

# When we set -Dmd5sum=md5sum the application will shell and run the local md5sum to calculate a md5.
# When we apply the -DpidwebserviceEndpoint and -DpidwebserviceKey we will override the or.property file settings.
java $JAVA_OPTS -DpidwebserviceEndpoint=$pidwebserviceEndpoint -DpidwebserviceKey=$pidwebserviceKey -Dmd5sum=md5sum -cp $manager "$instruction"
