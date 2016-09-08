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

    print('N,RECOVER')
    csv.field_size_limit(524288)
    n=0
    with open(file, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for _items in reader:
            n, expected, actual, match = [item for item in _items]
            if not match:
                lookup()


def usage():
    print('Usage: chunk_check.py -f [source file]')


def main(argv):
    sourcefile = None

    try:
        opts, args = getopt.getopt(argv, 'p:s:d:h',
                                   ['primary=', 'secondary=', 'delay=', 'help'])
    except getopt.GetoptError:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-p', '--primary'):
            sourcefile = arg

    assert sourcefile
    parse_csv(sourcefile)


if __name__ == '__main__':
    main(sys.argv[1:])