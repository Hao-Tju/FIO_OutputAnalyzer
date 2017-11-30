#!/usr/bin/python3

import os
import sys
import argparse

from struct import *

def minVal(line):
    start_pos = line.find('min') + 4
    end_pos = line[start_pos:].find(',') + start_pos

    return line[start_pos:end_pos]

def maxVal(line):
    start_pos = line.find('max') + 4
    end_pos = line[start_pos:].find(',') + start_pos

    return line[start_pos:end_pos]

def avgVal(line):
    start_pos = line.find('avg') + 4
    end_pos = line[start_pos:].find(',') + start_pos

    return line[start_pos:end_pos]

def stdevVal(line):
    start_pos = line.find('stdev') + 6

    return line[start_pos:].strip()

def FileProcess(filename,rec_type,avg_bw_log,sample_bw_log,slat_log,clat_log,lat_log,iops_log):
    file = open(filename)
    basename = os.path.basename(filename)
    pos = basename.find('-')
    blocksize = basename[:pos]
    analysis_flag = False
    rw_mode = ''
    rw_phase = ''
    iodepth = ''

    if filename.find('iodepth') != -1:
        pos = filename.find('iodepth') + 8
        end = filename[pos:].find('/') + pos
        iodepth = filename[pos:end]
    for line in file:
        if not analysis_flag and line.find('groupid') != -1:
            analysis_flag = True
            pos = line.strip().find(':')
            rw_mode = line.strip()[:pos]


        if (analysis_flag):
            if rec_type.find('iops') != -1 and line.find('IOPS') != -1:
                end_pos = line.strip().find(':')
                rw_phase = line.strip()[:end_pos]
                ParseIOPS(rw_mode, iodepth, blocksize, line, iops_log)
                ParseBandwidth(rw_mode, iodepth, rw_phase, blocksize, line, avg_bw_log, '')
            elif rec_type.find('sla') != -1 and line.find('slat') != -1:
                ParseLatency(rw_mode, iodepth, rw_phase, blocksize, line, rec_type, slat_log, clat_log, lat_log)
            elif rec_type.find('cla') != -1 and line.find('clat') != -1:
                ParseLatency(rw_mode, iodepth, rw_phase, blocksize, line, rec_type, slat_log, clat_log, lat_log)
            elif rec_type.find('lat') != -1 and line.find(' lat') != -1 and line.find('min') != -1:
                ParseLatency(rw_mode, iodepth, rw_phase, blocksize, line, rec_type, slat_log, clat_log, lat_log)
            elif rec_type.find('bw') != -1 and line.find('min') != -1:
                ParseBandwidth(rw_mode, iodepth, rw_phase, blocksize, line, '', sample_bw_log)

        if (analysis_flag and line.find('latency') != -1):
            analysis_flag = False
            rw_phase = ''

def FolderProcess(folder_name,rec_type,avg_bw_log,sample_bw_log,slat_log,clat_log,lat_log,iops_log):
    file_folder_lists = os.listdir(folder_name)
    print('Current folder(s) or file(s) needed to be processed:', file_folder_lists)
    for file in file_folder_lists:
        absolute_filepath = folder_name + '/' + file
        if (os.path.isfile(absolute_filepath)):
            print('Current file', absolute_filepath, 'is being processed.')
            FileProcess(absolute_filepath, rec_type, avg_bw_log, sample_bw_log, slat_log, clat_log, lat_log, iops_log)
        elif (os.path.isdir(absolute_filepath)):
#            print('Current folder', absolute_filepath, 'is being processed.')
            FolderProcess(absolute_filepath, rec_type, avg_bw_log, sample_bw_log, slat_log, clat_log, lat_log, iops_log)

def ParseLatency(rw_mode,iodepth,rw_phase,block_size,line,lat_mode,slat_log,clat_log,lat_log):
    lat_val = latType()
    if (lat_mode.find('sla') != -1):
        lat_val.kind = 'slat'
    elif (lat_mode.find('cla') != -1):
        lat_val.kind = 'clat'
    elif (lat_mode.find('lat') != -1):
        lat_val.kind = 'lat'

    if (line.find('lat') != -1 and line.find('min') != -1):
        start_pos = line.find('(')
        end_pos = line.find(')')
        lat_val.unit = line[start_pos + 1:end_pos].strip()
        if lat_val.unit == 'msec':
            lat_val.minVal = int(minVal(line)) * 1000
            lat_val.maxVal = int(maxVal(line)) * 1000
            lat_val.avgVal = float(avgVal(line)) * 1000
        elif lat_val.unit == 'usec':
            lat_val.minVal = int(minVal(line))
            lat_val.maxVal = int(maxVal(line))
            lat_val.avgVal = float(avgVal(line))
        else:
            print("New unit!", lat_val.unit)
            sys.exit("Sorry ...")
        lat_val.stdev = float(stdevVal(line))

        temp_key = dictKey(rw_phase, block_size, iodepth)
        if (lat_mode.find('sla') != -1 and line.find('slat') != -1):
            slat_log.setdefault(rw_mode, [])
            slat_log[rw_mode].append({temp_key: lat_val})
        elif (lat_mode.find('cla') != -1 and line.find('clat') != -1):
            clat_log.setdefault(rw_mode, [])
            clat_log[rw_mode].append({temp_key: lat_val})
        else:
            print('Key={0}, val={1}'.format(temp_key, lat_val))
            lat_log.setdefault(rw_mode, [])
            lat_log[rw_mode].append({temp_key: lat_val})
    #print("Latency:", latency_log)

def ParseBandwidth(rw_mode,iodepth,rw_phase,block_size,line,avg_bw,sample_bw):
    if line.find('BW') != -1:
        val_pos = line.find('BW') + 3
        val_end_pos = 0
        if line.find('MiB/s') != -1:
            val_end_pos = line.find('MiB')
            bw_val = line[val_pos:val_end_pos] + ' MiB/s'
        elif line.find('KiB/s') != -1:
            val_end_pos = line.find('KiB')
            bw_val = line[val_pos:val_end_pos] + ' KiB/s'

        temp_key = dictKey(rw_phase, block_size, iodepth)
        avg_bw.setdefault(rw_mode, [])
        avg_bw[rw_mode].append({temp_key: bw_val})
    elif line.find('bw') != -1 and line.find('min') != -1:
        pos = line.find('bw') + 4
        end_pos = line.find(')')
        bw = bwType()
        bw.unit = line[pos:end_pos].strip()
        bw.minVal = int(minVal(line))
        bw.maxVal = int(maxVal(line))
        bw.avgVal = float(maxVal(line))
        bw.stdev = float(stdevVal(line))

        temp_key = dictKey(rw_phase, block_size, iodepth)
        sample_bw.setdefault(rw_mode, [])
        sample_bw[rw_mode].append({temp_key: bw})
#        print('Key:', temp_key, 'Sample Bandwidth:', sample_bw)

def ParseIOPS(rw_mode,iodepth,block_size,line,iops_log):
    pos = line.strip().find(':')
    rw_phase = line.strip()[:pos]
    val_pos = line.find('IOPS') + 5
    val_end_pos = line.find(',')
    iops_val = line[val_pos:val_end_pos]
#    current_iops = iopsType()
#    current_iops.phase = rw_phase
#    current_iops.val = int(iops_val)

    #print('RW mode:', rw_mode, '-Phase:', rw_phase, '-IOPS:', iops_val)
    temp_key = dictKey(rw_phase, block_size, iodepth)
    iops_log.setdefault(rw_mode, [])
#    iops_log[rw_mode].append({temp_key: current_iops})
    iops_log[rw_mode].append({temp_key: iops_val})
    #print(iops_log)

def WriteLatLog(log_dir, output_format, lat_type, lat_log):
    for rw_mode,val in sorted(lat_log.items()):
        filename = log_dir + '/' + rw_mode + '_' + lat_type
        if output_format.find('csv') != -1:
            filename += '.csv'
            flag = False
            if not os.path.exists(filename):
                flag = True

            file = open(filename, 'a+')

            if flag:
                flag = False
                title_line = 'iodepth,rw_phase,blocksize,min(usec),max(usec),avg(usec),stdev\n'
                file.write(title_line)
                file.flush()

            for record in sorted(val, key=lambda k: list(k.keys())[0]):
                for temp_key,curr_lat in record.items():
                    content_line = temp_key.iodepth + ',' + temp_key.phase + ',' + str(temp_key.blocksize) + ',' \
                            + str(curr_lat.minVal) + ',' + str(curr_lat.maxVal) + ',' + str(curr_lat.avgVal) + ',' \
                            + str(curr_lat.stdev) + '\n'
                    file.write(content_line)
        if output_format.find('gpt') != -1 and lat_type.find('lat') != -1 and \
            lat_type.find('slat') == -1 and lat_type.find('clat') == -1:
            filename_1 = log_dir + '/' + rw_mode + '_lat_iod.dat'
            filename_2 = log_dir + '/' + rw_mode + '_lat_bs.dat'
            flag = False
            if not os.path.exists(filename_1):
                flag = True

            file = open(filename_1, 'a+')

            if flag:
                flag = False
                title_line = '# row\tiodepth\trw_phase\t4k\t16k\t32k\t64k\t128k\t256k\t512k\t1m\t4m\t8m\n'
                file.write(title_line)
                file.flush()

            iod_list = ['1','4','8','16','32']
            bs_list = ['4k','8k','16k','32k','64k','128k','256k','512k','1m','4m','8m']
            rw_phase_list = ['read','write']
            for rw in rw_phase_list:
                row = 1
                for iod in iod_list:
                    gpt_content_line = str(row) + '\t' + iod + '\t' + rw + '\t'
                    gpt_flag = False
                    for bs in bs_list:
                        gpt_key = dictKey(rw, bs, iod)
                        for item in val:
                            if gpt_key not in item:
                                continue
                            gpt_flag = True
                            gpt_content_line += str(item[gpt_key].avgVal)
                            if bs != '8m':
                                gpt_content_line += '\t'
                    gpt_content_line += '\n'
                    row += 1
                    if gpt_flag:
                        file.write(gpt_content_line)
                        file.flush()
            if not os.path.exists(filename_2):
                flag = True

            bs_file = open(filename_2, 'a+')
            if flag:
                flag = False
                title_line = '# row\tbs\trw_phase\t1\t4\t8\t16\t32\n'
                bs_file.write(title_line)
                bs_file.flush()
            for rw in rw_phase_list:
                row = 1
                for bs in bs_list:
                    gpt_content_line = str(row) + '\t' + bs + '\t' + rw + '\t'
                    gpt_flag = False
                    for iod in iod_list:
                        gpt_key = dictKey(rw, bs, iod)
                        for item in val:
                            if gpt_key not in item:
                                continue
                            gpt_flag = True
                            gpt_content_line += str(item[gpt_key].avgVal)
                            if iod != '32':
                                gpt_content_line += '\t'
                    gpt_content_line += '\n'
                    row += 1
                    if gpt_flag:
                        bs_file.write(gpt_content_line)
                        bs_file.flush()

def WriteBandwidthLog(log_dir, output_format, bw_type, bw_log):
    max_rw_mode = ''
    max_bw = '0'
    max_temp_key = dictKey('','','')
    for rw_mode,val in sorted(bw_log.items()):
        filename = log_dir + '/' + rw_mode + '_' + bw_type
        if output_format.find('csv') != -1:
            filename += '.csv'
            flag = False
            if not os.path.exists(filename):
                flag = True

            file = open(filename, 'a+')

            if flag:
                flag = False
                title_line = 'iodepth,rw_phase,blocksize'
                if bw_type == "avg_bw":
                    title_line += ',avg_bw\n'
                elif bw_type == "sample_bw":
                    title_line += ',min(KiB/s),max(KiB/s),avg(KiB/s),stdev\n'
                file.write(title_line)
                file.flush()

            for record in sorted(val, key=lambda k: list(k.keys())[0]):
                for temp_key,curr_bw_rec in record.items():
                    content_line = temp_key.iodepth + ',' + temp_key.phase + ',' + str(temp_key.blocksize)
                    if bw_type == "avg_bw":
                        content_line = content_line + ',' + str(curr_bw_rec) +'\n'
                        #print(temp_key, curr_bw_rec[:-6])
                        if max_bw == '0' or (curr_bw_rec.find('KiB') == -1 and float(max_bw[:-6]) < float(curr_bw_rec[:-6])):
                            max_bw = curr_bw_rec
                            max_rw_mode = rw_mode
                            max_temp_key.iodepth = temp_key.iodepth
                            max_temp_key.phase = temp_key.phase
                            max_temp_key.blocksize = temp_key.blocksize
                    elif bw_type == "sample_bw":
                        content_line = content_line + ',' + str(curr_bw_rec.minVal) + ',' + str(curr_bw_rec.maxVal) + ',' \
                                + str(curr_bw_rec.avgVal) + ',' + str(curr_bw_rec.stdev) + '\n'
                    file.write(content_line)
                    file.flush()
        if output_format.find('gpt') != -1 and bw_type.find('avg_bw') != -1:
            filename_1 = log_dir + '/' + rw_mode + '_' + bw_type + '_iod.dat'
            filename_2 = log_dir + '/' + rw_mode + '_' + bw_type + '_bs.dat'
            flag = False
            if not os.path.exists(filename_1):
                flag = True

            file = open(filename_1, 'a+')

            if flag:
                flag = False
                title_line = '# row\tiodepth\trw_phase\t4k\t16k\t32k\t64k\t128k\t256k\t512k\t1m\t4m\t8m\n'
                file.write(title_line)
                file.flush()

            iod_list = ['1','4','8','16','32']
            bs_list = ['4k','8k','16k','32k','64k','128k','256k','512k','1m','4m','8m']
            rw_phase_list = ['read','write']
            for rw in rw_phase_list:
                row = 1
                for iod in iod_list:
                    gpt_content_line = str(row) + '\t' + iod + '\t' + rw + '\t'
                    gpt_flag = False
                    for bs in bs_list:
                        gpt_key = dictKey(rw, bs, iod)
                        for item in val:
                            if gpt_key not in item:
                                continue
                            gpt_flag = True
                            bandw = ''
                            if item[gpt_key].find('KiB/s') != -1:
                                print("Convert KiB/s to MiB/s ...")
                                bandw = str(float(item[gpt_key][:-6]) / 1024)
                            else:
                                bandw = item[gpt_key][:-6]
                            gpt_content_line += bandw
                            if bs != '8m':
                                gpt_content_line += '\t'
                    gpt_content_line += '\n'
                    row += 1
                    if gpt_flag:
                        file.write(gpt_content_line)
                        file.flush()
            if not os.path.exists(filename_2):
                flag = True

            bs_file = open(filename_2, 'a+')
            if flag:
                flag = False
                title_line = '# row\tbs\trw_phase\t1\t4\t8\t16\t32\n'
                bs_file.write(title_line)
                bs_file.flush()
            for rw in rw_phase_list:
                row = 1
                for bs in bs_list:
                    gpt_content_line = str(row) + '\t' + bs + '\t' + rw + '\t'
                    gpt_flag = False
                    for iod in iod_list:
                        gpt_key = dictKey(rw, bs, iod)
                        for item in val:
                            if gpt_key not in item:
                                continue
                            gpt_flag = True
                            bandw = ''
                            if item[gpt_key].find('KiB/s') != -1:
                                print("Convert KiB/s to MiB/s ...")
                                bandw = str(float(item[gpt_key][:-6]) / 1024)
                            else:
                                bandw = item[gpt_key][:-6]
                            gpt_content_line += bandw
                            if iod != '32':
                                gpt_content_line += '\t'
                    gpt_content_line += '\n'
                    row += 1
                    if gpt_flag:
                        bs_file.write(gpt_content_line)
                        bs_file.flush()

    if bw_type == 'avg_bw':
        print("RW Mode={0}, IO Depth={1}, RW Phase={2}, Block Size={3}, Max BW={4}".format( \
                max_rw_mode, max_temp_key.iodepth, max_temp_key.phase, max_temp_key.blocksize, max_bw))

def WriteIOPSLog(log_dir, output_format, iops_log):
    max_iops = '0'
    max_rw_mode = ''
    max_temp_key = dictKey('','','')
    for rw_mode,val in sorted(iops_log.items()):
        filename = log_dir + '/' + rw_mode + '_IOPS'
        if output_format.find('csv') != -1:
            filename += '.csv'
            flag = False
            if not os.path.exists(filename):
                flag = True

            file = open(filename, 'a+')

            if flag:
                flag = False
                title_line = 'iodepth,rw_phase,blocksize,IOPS\n'
                file.write(title_line)
                file.flush()

            for record in sorted(val, key=lambda k: list(k.keys())[0]):
                for temp_key,curr_iops in record.items():
                    content_line = temp_key.iodepth + ',' + temp_key.phase + ',' + str(temp_key.blocksize) + ','
                    if curr_iops.find('k') != -1:
                        curr_iops = curr_iops[:-1]
                        curr_iops = str(int(float(curr_iops) * 1000))
                    content_line += curr_iops + '\n'
                    if (int(max_iops) < int(curr_iops)):
                        max_iops = curr_iops
                        max_rw_mode = rw_mode
                        max_temp_key.iodepth = temp_key.iodepth
                        max_temp_key.phase = temp_key.phase
                        max_temp_key.blocksize = temp_key.blocksize
                    file.write(content_line)
                    file.flush()

        if output_format.find('gpt') != -1:
            filename_1 = log_dir + '/' + rw_mode + '_IOPS_iod.dat'
            filename_2 = log_dir + '/' + rw_mode + '_IOPS_bs.dat'
            flag = False
            if not os.path.exists(filename_1):
                flag = True
            file = open(filename_1, 'a+')

            if flag:
                flag = False
                title_line = '# row\tiodepth\trw_phase\t4k\t16k\t32k\t64k\t128k\t256k\t512k\t1m\t4m\t8m\n'
                file.write(title_line)
                file.flush()

            iod_list = ['1','4','8','16','32']
            bs_list = ['4k','8k','16k','32k','64k','128k','256k','512k','1m','4m','8m']
            rw_phase_list = ['read','write']
            for rw in rw_phase_list:
                row = 1
                for iod in iod_list:
                    gpt_content_line = str(row) + '\t' + iod + '\t' + rw + '\t'
                    gpt_flag = False
                    for bs in bs_list:
                        gpt_key = dictKey(rw, bs, iod)
                        for item in val:
                            if gpt_key not in item:
                                continue
                            gpt_flag = True
                            iops_bs = ''
                            if item[gpt_key].find('k') != -1:
                                iops_bs = str(int(float(item[gpt_key][:-1]) * 1000))
                            else:
                                iops_bs = item[gpt_key]
                            gpt_content_line += iops_bs
                            if bs != '8m':
                                gpt_content_line += '\t'
                    gpt_content_line += '\n'
                    row += 1
                    if gpt_flag:
                        file.write(gpt_content_line)
                        file.flush()
            if not os.path.exists(filename_2):
                flag = True

            bs_file = open(filename_2, 'a+')
            if flag:
                flag = False
                title_line = '# row\tbs\trw_phase\t1\t4\t8\t16\t32\n'
                bs_file.write(title_line)
                bs_file.flush()
            for rw in rw_phase_list:
                row = 1
                for bs in bs_list:
                    gpt_content_line = str(row) + '\t' + bs + '\t' + rw + '\t'
                    gpt_flag = False
                    for iod in iod_list:
                        gpt_key = dictKey(rw, bs, iod)
                        for item in val:
                            if gpt_key not in item:
                                continue
                            gpt_flag = True
                            iops_iod = ''
                            if item[gpt_key].find('k') != -1:
                                iops_iod = str(int(float(item[gpt_key][:-1]) * 1000))
                            else:
                                iops_iod = item[gpt_key]
                            gpt_content_line += iops_iod
                            if iod != '32':
                                gpt_content_line += '\t'
                    gpt_content_line += '\n'
                    row += 1
                    if gpt_flag:
                        bs_file.write(gpt_content_line)
                        bs_file.flush()


    print("MAX IOPS: RW Mode={0}, IO Depth={1}, RW Phase={2}, Block Size={3}, IOPS={4}".format( \
            max_rw_mode, max_temp_key.iodepth, max_temp_key.phase, max_temp_key.blocksize, max_iops))


