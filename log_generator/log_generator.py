#!/usr/bin/python
# coding=utf-8

import time
from datetime import datetime
import argparse


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Fake log generator', add_help=True)

    parser.add_argument('-v', '--verbose', action='store_true', default=False, dest='verbose', help='Verbose mode')
    parser.add_argument('-i', '--input_file', action='store', required=True, dest='input_file', help='Input file with sample log')
    parser.add_argument('-o', '--output_file', action='store', required=True, dest='output_file', help='Output log file name')
    parser.add_argument('-m', '--mode', action='store', choices=['time', 'count'], required=True, dest='mode', help='Mode of generate - by time or by count of records')
    parser.add_argument('-c', '--count', action='store', dest='count', type=int, default=0, help='Count of record to produce')
    parser.add_argument('-t', '--time', action='store', dest='time', type=int, default=0, help='Time to work (sec.)')
    parser.add_argument('-d', '--delay', action='store', dest='delay', type=float, default=0, help='Delay between log writes (sec). Default=0')

    args = parser.parse_args()

    if args.verbose:
        print args

    sample = None
    output = None
    try:
        sample = open(args.input_file, 'r').read()
    except Exception as e:
        print "Can't open input file:", e
        exit(1)

    try:
        output = open(args.output_file, 'w')
    except Exception as e:
        print "Can't open output file:", e
        exit(2)

    timestart = time.time()
    i = 0
    if args.mode == 'count':
        while i < args.count:
            output.write(sample.format(str(datetime.now())))
            time.sleep(args.delay)
            i += 1
    else:
        while time.time() - timestart < args.time:
            output.write(sample.format(str(datetime.now())))
            i += 1
            time.sleep(args.delay)

    print 'Generation done.\nLines has been generated:', i, '\nTime spent:', round(time.time()-timestart, 3)
