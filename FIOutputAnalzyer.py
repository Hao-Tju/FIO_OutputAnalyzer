#!/usr/bin/python3

import argparse

from function import *

def ParseArgs():
    parser = argparse.ArgumentParser(description='Convert the default FIO output file(s) to csv format file(s)!')
    parser.add_argument('-f', '--file', required=False, type=str, \
            help='The FIO output files needed to be converted. e.g. -f test.txt, -f test.txt,test_1.txt')
    parser.add_argument('-d', '--directory', required=False, type=str, \
            help='The directory where FIO output files are located in.')
    parser.add_argument('-c', '--content', required=False, type=str, default='lat,bw,iops', \
            help='The content needed to be processed! (Valid value: lat for latency, bw for bandwidth, iops for IOPS, \
                sla for submission latency, cla for completion latency. These value can be combined use comma.)')
    parser.add_argument('-o', '--output', required=True, type=str, \
            help='The directory used to store result csv files.')
    parser.add_argument('-of', '--outformat', required=False, type=str, default='csv', \
            help='The output file format. (Valid value: csv for csv format file, gpt for gnuplot format file. \
            Multiple value should be splited by comma.)')
    args = parser.parse_args()

    return args

if __name__ == '__main__':
    avg_bw_log = {}
    sample_bw_log = {}
    slat_log = {}
    clat_log = {}
    lat_log = {}
    iops_log = {}
    directories = []
    files = []

    args = ParseArgs()
    output_dir = args.output
    output_format = args.outformat
    rec_type = args.content
    folder_args = args.directory
    files_args = args.file
    if folder_args == None:
        print('There is no directory needed to be analyzed!')
        if files_args == None:
            print('Use -h option to check the USAGE!')
            exit()
    else:
        directories = folder_args.split(',')

    if (directories != []):
        for directory in directories:
            if (os.path.isdir(directory)):
                print("Current directory being processed: ", directory)
                FolderProcess(directory, rec_type, avg_bw_log, sample_bw_log, slat_log, clat_log, lat_log, iops_log)
                #print("AVG BW:", avg_bw_log, "\nSample BW:", sample_bw_log, \
                #        "\nSubmission Latency:", slat_log, "\nCompletion Latency", clat_log, \
                #        "\nLatency:", lat_log, "\nIOPS:", iops_log)
            else:
                print("ERROR!", directory, "is not a directory!")

    if files_args == None:
        print('There is no files needed to be analyzed!')
        if folder_args == None:
            print('Use -h option to check the USAGE!')
            exit()
    else:
        files = files_args.split(',')

    if (files != []):
        for file in files:
            if (os.path.isfile(file)):
                print ('Current file being processed: ', file)
                FileProcess(file, rec_type, avg_bw_log, sample_bw_log, slat_log, clat_log, lat_log, iops_log)
                #print("AVG BW:", avg_bw_log, "\nSample BW:", sample_bw_log, \
                #        "\nSubmission Latency:", slat_log, "\nCompletion Latency", clat_log, \
                #        "\nLatency:", lat_log, "\nIOPS:", iops_log)
            else:
                print("ERROR!", file, "is not a file!")

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    if rec_type.find('bw') != -1:
        WriteBandwidthLog(output_dir, output_format, 'avg_bw', avg_bw_log)
        WriteBandwidthLog(output_dir, output_format, 'sample_bw', sample_bw_log)

    if rec_type.find('iops') != -1:
        WriteIOPSLog(output_dir, output_format, iops_log)

    if rec_type.find('lat') != -1:
        WriteLatLog(output_dir, output_format, 'lat', lat_log)

    if rec_type.find('sla') != -1:
        WriteLatLog(output_dir, output_format, 'slat', slat_log)

    if rec_type.find('cla') != -1:
        WriteLatLog(output_dir, output_format, 'clat', clat_log)
