#
# Runs ImageMagick to convert an image into a ( smaller ) image. 
# Then ingests the derivative into the correct bucket.
#
source $scripts/shared/parameters.sh $@

sourceFile=/tmp/$md5.$sourceBuckets.$sourceFileExtension
targetFile=/tmp/$md5.$targetBucket
if [ -f $sourceFile ]; then
	echo "Using existing cached file on $sourceFile"
else
	source $scripts/shared/get.sh $@ -bucket $sourceBuckets -l $sourceFile
fi

# Run the convert script to create derivative.
if [ -f $sourceFile ]; then
	echo "Creating derivative from $sourceFile"
	cmd=`php $scripts/shared/image.derivative.php -i $sourceFile -l $targetBucket -d $database -p $pid -s $scripts/shared/content.js -o $targetFile `
	echo "cmd=$cmd"
	convert $cmd
else
	echo "Could not find sourceFile: $sourceFile"
fi

# The derivative script has added a jpg extension to the targetFile, which we take over here.
targetFile=$targetFile$.jpg
if [ -f $targetFile ]; then
	$scripts/shared/put.sh $@ contentType image/jpeg -bucket $targetBucket -l $targetFile
fi

if [ -f $sourceFile ]; then
	rm -f $sourceFile
fi


