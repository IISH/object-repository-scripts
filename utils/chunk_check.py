#!/usr/bin/env python
#
# chunk_check.py
#
# Recalculate the md5 hash

import binascii
import csv
import getopt
import hashlib
import sys


def parse_csv(file):

    csv.field_size_limit(524288)
    with open(file, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for _items in reader:
            host = _items[0]
            _id = _items[1]
            n = _items[2]
            files_id = _items[3]
            expected_md5 = _items[4]
            data = _items[5]
            actual_md5 = hashlib.md5(binascii.unhexlify(data)).hexdigest()
            compare = int(expected_md5, 16) == int(actual_md5, 16)
            print(host + ',' + _id + ',' + n + ',' + files_id + ',' + expected_md5 + ',' + actual_md5 + ',' + str(compare))

def usage():
    print('Usage: chunk_check.py -f [source file]')


def main(argv):
    sourcefile = None

    try:
        opts, args = getopt.getopt(argv, 'f:h',
                                   ['file=', 'help'])
    except getopt.GetoptError:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-f', '--file'):
            sourcefile = arg

    assert sourcefile
    parse_csv(sourcefile)


if __name__ == '__main__':
    main(sys.argv[1:])