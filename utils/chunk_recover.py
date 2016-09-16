#!/usr/bin/env python
#
# chunk_check.py
#
# Recalculate the md5 hash

import csv
import getopt
import sys


def parse_csv(primary, secondary, delay):
    p_dict = load(primary, False)
    s_p_dict = load(secondary)
    d_p_dict = load(delay)

    for n in p_dict:
        if n in s_p_dict:
            print('True,' + n + ',' + s_p_dict[n])
        elif n in d_p_dict:
            print('True,' + n + ',' + d_p_dict[n])
        else:
            print('False,' + n + ',' + p_dict[n])


def load(file, accept=True):
    d = dict()
    with open(file, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',')
        for _items in reader:
            host, _id, n, files_id, expected, actual, match = [item for item in _items]
            if str2bool(match) == accept:
                d[n] = host
    return d

def str2bool(v):
    return v.lower() in ('yes', 'true', 't', '1')


def usage():
    print('Usage: chunk_recover.py -p [primart file] -s [secondary file] -d [delay file]')


def main(argv):
    primary = secondary = delay = None

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
            primary = arg
        elif opt in ('-s', '--secondary'):
            secondary = arg
        elif opt in ('-d', '--delay'):
            delay = arg
        else:
            print 'Unknown argument: ' + opt
            usage()
            sys.exit(1)

    assert primary
    assert secondary
    assert delay
    parse_csv(primary, secondary, delay)


if __name__ == '__main__':
    main(sys.argv[1:])
