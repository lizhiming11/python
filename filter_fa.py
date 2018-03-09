#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
from Bio import SeqIO
import re
parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter,
                                 description='Select the fasta file.')
parser.add_argument('-i', '--infile', help='Original fasta file.')
parser.add_argument('-o','--output_file', help='output fasta file.')
parser.add_argument('-f','--filter',  help='sequence name to be filtered')

args = parser.parse_args()
a1 = args.infile
a2 = args.output_file
a3 = args.filter

def save_file(x):
    f1 = open(a2, "w")
    seq = SeqIO.parse(a1, 'fasta')
    for line in seq:
        if line.id in x:
            print>>f1,'>'+line.id+'\n'+line.seq

    f1.close()
    seq.close()
def read_file(x):
    f = open(x)
    f_data = f.readlines()
    for i in range(len(f_data)):
        f_data[i] = f_data[i].strip("\n")

    f.close()
    save_file(f_data)

read_file(a3)