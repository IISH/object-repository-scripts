if [ $testCounter == $testTotal ] ; then
    echo "Unit test ok: $testCounter / $testTotal"
    exit 0
fi

echo "Test failed: $testCounter / $testTotal"
exit -1

