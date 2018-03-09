#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import gzip
import re

parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter,
                                 description='Select the fasta file.')
parser.add_argument('-i', '--infile', help='Original fasta file.')
parser.add_argument('-o','--output_file', help='output fasta file.')
parser.add_argument('-f','--filter',  help='Number of split')

args = parser.parse_args()
infile = args.infile
a2 = args.output_file
a1 = int(args.filter)

#infile = "split_9.fa.gz"
#a1 = 10
#a2 = "split"
def open_file(x):
    if x[-len("gz"):] =="gz":
        x = gzip.GzipFile(x, "r")
    else:
        x= open(x,"r")
    return x


def read_line(x):
    x = open_file(x)
    file1 = x.readline()
    sum_a = 0
    while file1:
        a = len(file1)
        sum_a = sum_a+a
        file1 = x.readline()
    x.close()
    return sum_a

def split_fasta(x):
    cutoff = sum_file/a1
    x = open_file(x)
    file1 = x.readline()
    for i in range(a1):
        sum_a = 0
        f = open(a2 + str(i + 1) + ".fa", 'w')
        while file1:
            f.writelines(file1)
            file1 = x.readline()
            a = len(file1)
            sum_a = sum_a + a
            if sum_a>cutoff:
                if ">" in file1:
                    break

sum_file = read_line(infile)
split_fasta(infile)


