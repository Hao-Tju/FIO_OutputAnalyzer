#!/bin/bash

set -e

plotBsPNG()
{
  # $1 for file folder
  # $2 for data file
  # $3 for the label of y axis
  # $4 for the filename without file format
  echo "Plotting ${1}/png/${4}.png"
  gnuplot <<-bsEOF
  set terminal png
  set output '${1}/png/${4}.png'
  set ylabel '${3}'
  set xlabel 'Blocksize'
  set xtic('4k' 1,'8k' 2,'16k' 3,'32k' 4,'64k' 5,'128k' 6,'256k' 7,'512k' 8, \
    '1m' 9,'4m' 10,'8m' 11)
  plot \
    '$2' u 1:4 ti 'iodepth=1' w lp lt 2, \
    '$2' u 1:5 ti 'iodepth=4' w lp lt 3, \
    '$2' u 1:6 ti 'iodepth=8' w lp lt 4, \
    '$2' u 1:7 ti 'iodepth=16' w lp lt 5, \
    '$2' u 1:8 ti 'iodepth=32' w lp lt 6
bsEOF
}

gnuPlot()
{
  # $1 for file folder
  # $2 for bname
  # $3 for format
  bname_no_ft=${2%%.*}
  temp_str=${bname_no_ft#*_}
  y_axis=${temp_str%_*}
  y_label=''
  rw_mode=${bname_no_ft%%_*}
  data_type=''

  echo "Now is processing $2"
  if [ $y_axis = 'lat' ]; then
    y_label="Latency(usec)"
    data_type='lat'
  elif [ $y_axis = 'IOPS' ]; then
    y_label='IOPS'
    data_type='iops'
  elif [ $y_axis = 'avg_bw' ]; then
    y_label='Average Bandwidth (MiB/s)'
    data_type='bw'
  fi

  :<<commentEOF
  echo "data_type=$data_type"
  for line in `sed -n '2~1p' ${1}/min_max_val_${data_type}.csv`
  do
    curr_rw_mode=$(awk -F, '{print $1}' <<<"$line")
    if [ $curr_rw_mode = $rw_mode ]; then
      curr_min_rw_phase=$(awk -F, '{print $2}' <<<"$line")
      curr_min_iodepth=$(awk -F, '{print $3}' <<<"$line")
      curr_min_blocksize=$(awk -F, '{print $4}' <<<"$line")
      curr_min=$(awk -F, '{print $5}' <<<"$line")
      curr_max_rw_phase=$(awk -F, '{print $6}' <<<"$line")
      curr_max_iodepth=$(awk -F, '{print $7}' <<<"$line")
      curr_max_blcoksize=$(awk -F, '{print $8}' <<<"$line")
      curr_max=$(awk -F, '{print $9}' <<<"$line")
    fi
  done

  case "$curr_min_blocksize" in
    "4k") min_bs_x_pos=1 ;;
    "8k") min_bs_x_pos=2 ;;
    "16k") min_bs_x_pos=3 ;;
    "32k") min_bs_x_pos=4 ;;
    "64k") min_bs_x_pos=5 ;;
    "128k") min_bs_x_pos=6 ;;
    "256k") min_bs_x_pos=7 ;;
    "512k") min_bs_x_pos=8 ;;
    "1m") min_bs_x_pos=9 ;;
    "4m") min_bs_x_pos=10 ;;
    "8m") min_bs_x_pos=11 ;;
  esac

  case "$curr_min_iodepth" in
    "1") min_iod_x_pos=1 ;;
    "4") min_iod_x_pos=2 ;;
    "8") min_iod_x_pos=3 ;;
    "16") min_iod_x_pos=4 ;;
    "32") min_iod_x_pos=5 ;;
  esac

  case "$curr_max_blocksize" in
    "4k") max_bs_x_pos=1 ;;
    "8k") max_bs_x_pos=2 ;;
    "16k") max_bs_x_pos=3 ;;
    "32k") max_bs_x_pos=4 ;;
    "64k") max_bs_x_pos=5 ;;
    "128k") max_bs_x_pos=6 ;;
    "256k") max_bs_x_pos=7 ;;
    "512k") max_bs_x_pos=8 ;;
    "1m") max_bs_x_pos=9 ;;
    "4m") max_bs_x_pos=10 ;;
    "8m") max_bs_x_pos=11 ;;
  esac

  case "$curr_max_iodepth" in
    "1") max_iod_x_pos=1 ;;
    "4") max_iod_x_pos=2 ;;
    "8") max_iod_x_pos=3 ;;
    "16") max_iod_x_pos=4 ;;
    "32") max_iod_x_pos=5 ;;
  esac

  set label "(${curr_min_iodepth},${curr_min})" at ${min_iod_x_pos},${curr_min} center tc palette z
  set label "(${curr_max_iodepth},${curr_max})" at ${max_iod_x_pos},${curr_max} center tc palette z
  set label "(${curr_min_blocksize},${curr_min})" at ${min_bs_x_pos},${curr_min} center tc palette z
  set label "(${curr_min_blocksize},${curr_max})" at ${min_bs_x_pos},${curr_max} center tc palette z
commentEOF
  var=${bname_no_ft##*_}
  if [ $var = 'iod' ]; then
    echo "Plotting ${bname_no_ft}.png"
    #plotIodPNG $1 ${1}/${2} $y_label $bname_no_ft
    gnuplot <<- iodEOF
    set terminal png
    set output '${1}/png/${bname_no_ft}.png'
    set ylabel '${y_label}'
    set xlabel 'IO Depth'
    set xtic('1' 1, '4' 2, '8' 3, '16' 4, '32' 5)
    plot \
      '${1}/${2}' u 1:4 ti 'bs=4k' w lp lt 2, \
      '${1}/${2}' u 1:5 ti 'bs=8k' w lp lt 3, \
      '${1}/${2}' u 1:6 ti 'bs=16k' w lp lt 4, \
      '${1}/${2}' u 1:7 ti 'bs=32k' w lp lt 5, \
      '${1}/${2}' u 1:8 ti 'bs=64k' w lp lt 6, \
      '${1}/${2}' u 1:9 ti 'bs=128k' w lp lt 7, \
      '${1}/${2}' u 1:10 ti 'bs=256k' w lp lt 8, \
      '${1}/${2}' u 1:11 ti 'bs=512k' w lp lt 9, \
      '${1}/${2}' u 1:12 ti 'bs=1M' w lp lt 10, \
      '${1}/${2}' u 1:13 ti 'bs=4M' w lp lt 11, \
      '${1}/${2}' u 1:14 ti 'bs=8M' w lp lt 12
iodEOF
  elif [ $var = 'bs' ]; then
    echo "Plotting ${bname_no_ft}.png"
    #plotBsPNG $1 ${1}/${2} $y_label $bname_no_ft
    gnuplot <<-bsEOF
    set terminal png
    set output '${1}/png/${bname_no_ft}.png'
    set ylabel '${y_label}'
    set xlabel 'Blocksize'
    set xtic('4k' 1,'8k' 2,'16k' 3,'32k' 4,'64k' 5,'128k' 6,'256k' 7,'512k' 8, \
      '1m' 9,'4m' 10,'8m' 11)
    plot \
      '${1}/${2}' u 1:4 ti 'iodepth=1' w lp lt 2, \
      '${1}/${2}' u 1:5 ti 'iodepth=4' w lp lt 3, \
      '${1}/${2}' u 1:6 ti 'iodepth=8' w lp lt 4, \
      '${1}/${2}' u 1:7 ti 'iodepth=16' w lp lt 5, \
      '${1}/${2}' u 1:8 ti 'iodepth=32' w lp lt 6
bsEOF
  fi
}

gnuPlot2Phase()
{
  # $1 for file folder
  # $2 for bname
  # $3 for format
  rw_mode=${2%%_*}
  bname_no_ft=${2%%.*}
  temp_str=${bname_no_ft#*_}
  y_axis=${temp_str%_*}
  y_label='lalal'
  rw_mode=${bname_no_ft%%_*}
  data_type=''

  echo "Now is processing $2"
  if [ $y_axis = 'lat' ]; then
    y_label="Latency(usec)"
    data_type='lat'
  elif [ $y_axis = 'IOPS' ]; then
    y_label='IOPS'
    data_type='iops'
  elif [ $y_axis = 'avg_bw' ]; then
    y_label='Average Bandwidth (MiB/s)'
    data_type='bw'
  fi

  if [ ! -d ${1}/tmp_dat ]; then
    mkdir -p ${1}/tmp_dat
  fi

  var=${bname_no_ft##*_}
  if [ $var = 'iod' ]; then
    sed -n '1,6p' ${1}/${bname_no_ft}.dat >> ${1}/tmp_dat/${bname_no_ft}_read.dat
    sed -e '1p' -n ${1}/${bname_no_ft}.dat >> ${1}/tmp_dat/${bname_no_ft}_write.dat
    sed -n '7,$p' ${1}/${bname_no_ft}.dat >> ${1}/tmp_dat/${bname_no_ft}_write.dat
  elif [ $var = 'bs' ]; then
    sed -n '1,12p' ${1}/${bname_no_ft}.dat >> ${1}/tmp_dat/${bname_no_ft}_read.dat
    sed -e '1p' -n ${1}/${bname_no_ft}.dat >> ${1}/tmp_dat/${bname_no_ft}_write.dat
    sed -n '13,$p' ${1}/${bname_no_ft}.dat >> ${1}/tmp_dat/${bname_no_ft}_write.dat
  fi

  :<<commentEOF
  for line in `sed -n '2~1p' ${1}/min_max_val_${data_type}.csv`
  do
    curr_rw_mode=$(awk -F, '{print $1}' <<<"$line")
    if [ $curr_rw_mode = $rw_mode ]; then
      curr_rw_phase=$(awk -F, '{print $2}' <<<"$line")
      if [ $curr_rw_phase = 'read' ]; then
        curr_r_min_iodepth=$(awk -F, '{print $3}' <<<"$line")
        curr_r_min_blocksize=$(awk -F, '{print $4}' <<<"$line")
        curr_r_min=$(awk -F, '{print $5}' <<<"$line")
        curr_r_max_iodepth=$(awk -F, '{print $7}' <<<"$line")
        curr_r_max_blcoksize=$(awk -F, '{print $8}' <<<"$line")
        curr_r_max=$(awk -F, '{print $9}' <<<"$line")
      elif [ $curr_rw_phase = 'write' ]; then
        curr_w_min_iodepth=$(awk -F, '{print $3}' <<<"$line")
        curr_w_min_blocksize=$(awk -F, '{print $4}' <<<"$line")
        curr_w_min=$(awk -F, '{print $5}' <<<"$line")
        curr_w_max_iodepth=$(awk -F, '{print $7}' <<<"$line")
        curr_w_max_blcoksize=$(awk -F, '{print $8}' <<<"$line")
        curr_w_max=$(awk -F, '{print $9}' <<<"$line")
      fi
    fi
  done

  case "$curr_r_min_blocksize" in
    "4k") min_r_bs_x_pos=1 ;;
    "8k") min_r_bs_x_pos=2 ;;
    "16k") min_r_bs_x_pos=3 ;;
    "32k") min_r_bs_x_pos=4 ;;
    "64k") min_r_bs_x_pos=5 ;;
    "128k") min_r_bs_x_pos=6 ;;
    "256k") min_r_bs_x_pos=7 ;;
    "512k") min_r_bs_x_pos=8 ;;
    "1m") min_r_bs_x_pos=9 ;;
    "4m") min_r_bs_x_pos=10 ;;
    "8m") min_r_bs_x_pos=11 ;;
  esac

  case "$curr_r_min_iodepth" in
    "1") min_r_iod_x_pos=1 ;;
    "4") min_r_iod_x_pos=2 ;;
    "8") min_r_iod_x_pos=3 ;;
    "16") min_r_iod_x_pos=4 ;;
    "32") min_r_iod_x_pos=5 ;;
  esac

  case "$curr_r_max_blocksize" in
    "4k") max_r_bs_x_pos=1 ;;
    "8k") max_r_bs_x_pos=2 ;;
    "16k") max_r_bs_x_pos=3 ;;
    "32k") max_r_bs_x_pos=4 ;;
    "64k") max_r_bs_x_pos=5 ;;
    "128k") max_r_bs_x_pos=6 ;;
    "256k") max_r_bs_x_pos=7 ;;
    "512k") max_r_bs_x_pos=8 ;;
    "1m") max_r_bs_x_pos=9 ;;
    "4m") max_r_bs_x_pos=10 ;;
    "8m") max_r_bs_x_pos=11 ;;
  esac

  case "$curr_r_max_iodepth" in
    "1") max_r_iod_x_pos=1 ;;
    "4") max_r_iod_x_pos=2 ;;
    "8") max_r_iod_x_pos=3 ;;
    "16") max_r_iod_x_pos=4 ;;
    "32") max_r_iod_x_pos=5 ;;
  esac

  case "$curr_w_min_blocksize" in
    "4k") min_w_bs_x_pos=1 ;;
    "8k") min_w_bs_x_pos=2 ;;
    "16k") min_w_bs_x_pos=3 ;;
    "32k") min_w_bs_x_pos=4 ;;
    "64k") min_w_bs_x_pos=5 ;;
    "128k") min_w_bs_x_pos=6 ;;
    "256k") min_w_bs_x_pos=7 ;;
    "512k") min_w_bs_x_pos=8 ;;
    "1m") min_w_bs_x_pos=9 ;;
    "4m") min_w_bs_x_pos=10 ;;
    "8m") min_w_bs_x_pos=11 ;;
  esac

  case "$curr_w_min_iodepth" in
    "1") min_w_iod_x_pos=1 ;;
    "4") min_w_iod_x_pos=2 ;;
    "8") min_w_iod_x_pos=3 ;;
    "16") min_w_iod_x_pos=4 ;;
    "32") min_w_iod_x_pos=5 ;;
  esac

  case "$curr_w_max_blocksize" in
    "4k") max_w_bs_x_pos=1 ;;
    "8k") max_w_bs_x_pos=2 ;;
    "16k") max_w_bs_x_pos=3 ;;
    "32k") max_w_bs_x_pos=4 ;;
    "64k") max_w_bs_x_pos=5 ;;
    "128k") max_w_bs_x_pos=6 ;;
    "256k") max_w_bs_x_pos=7 ;;
    "512k") max_w_bs_x_pos=8 ;;
    "1m") max_w_bs_x_pos=9 ;;
    "4m") max_w_bs_x_pos=10 ;;
    "8m") max_w_bs_x_pos=11 ;;
  esac

  case "$curr_w_max_iodepth" in
    "1") max_w_iod_x_pos=1 ;;
    "4") max_w_iod_x_pos=2 ;;
    "8") max_w_iod_x_pos=3 ;;
    "16") max_w_iod_x_pos=4 ;;
    "32") max_w_iod_x_pos=5 ;;
  esac

  set label "(${curr_r_min_iodepth},${curr_r_min})" at ${min_r_iod_x_pos},${curr_r_min} center tc palette z
  set label "(${curr_r_max_iodepth},${curr_r_max})" at ${max_r_iod_x_pos},${curr_r_max} center tc palette z
  set label "(${curr_w_min_iodepth},${curr_w_min})" at ${min_w_iod_x_pos},${curr_w_min} center tc palette z
  set label "(${curr_w_max_iodepth},${curr_w_max})" at ${max_w_iod_x_pos},${curr_w_max} center tc palette z
  set label "(${curr_r_min_blocksize},${curr_r_min})" at ${min_r_bs_x_pos},${curr_r_min} center tc palette z
  set label "(${curr_r_min_blocksize},${curr_r_max})" at ${min_r_bs_x_pos},${curr_r_max} center tc palette z
  set label "(${curr_w_min_blocksize},${curr_w_min})" at ${min_w_bs_x_pos},${curr_w_min} center tc palette z
  set label "(${curr_w_min_blocksize},${curr_w_max})" at ${min_w_bs_x_pos},${curr_w_max} center tc palette z
commentEOF
  curr_read_dat=${1}/tmp_dat/${bname_no_ft}_read.dat
  curr_write_dat=${1}/tmp_dat/${bname_no_ft}_write.dat
  if [ $var = 'iod' ]; then
    echo "Plotting ${bname_no_ft}.png"
    gnuplot <<- iodEOF
    set terminal pngcairo dashed enhanced size 640,1280
    set output '${1}/png/${bname_no_ft}.png'
    set ylabel '${y_label}'
    set xlabel 'IO Depth'
    set xtic('1' 1, '4' 2, '8' 3, '16' 4, '32' 5)
    set multiplot
    set origin 0.0,0.5
    set size 1.0,0.5
    set title "${y_label} in read phase"
    plot \
      '${curr_read_dat}' u 1:4 ti 'bs=4k' w lp lt 2, \
      '${curr_read_dat}' u 1:5 ti 'bs=8k' w lp lt 3, \
      '${curr_read_dat}' u 1:6 ti 'bs=16k' w lp lt 4, \
      '${curr_read_dat}' u 1:7 ti 'bs=32k' w lp lt 5, \
      '${curr_read_dat}' u 1:8 ti 'bs=64k' w lp lt 6, \
      '${curr_read_dat}' u 1:9 ti 'bs=128k' w lp lt 7, \
      '${curr_read_dat}' u 1:10 ti 'bs=256k' w lp lt 8, \
      '${curr_read_dat}' u 1:11 ti 'bs=512k' w lp lt 9, \
      '${curr_read_dat}' u 1:12 ti 'bs=1M' w lp lt 10, \
      '${curr_read_dat}' u 1:13 ti 'bs=4M' w lp lt 11, \
      '${curr_read_dat}' u 1:14 ti 'bs=8M' w lp lt 12
    set origin 0.0,0.0
    set size 1.0,0.5
    set title "${y_label} in write phase"
    plot \
      '${curr_write_dat}' u 1:4 ti 'bs=4k' w lp lt 2, \
      '${curr_write_dat}' u 1:5 ti 'bs=8k' w lp lt 3, \
      '${curr_write_dat}' u 1:6 ti 'bs=16k' w lp lt 4, \
      '${curr_write_dat}' u 1:7 ti 'bs=32k' w lp lt 5, \
      '${curr_write_dat}' u 1:8 ti 'bs=64k' w lp lt 6, \
      '${curr_write_dat}' u 1:9 ti 'bs=128k' w lp lt 7, \
      '${curr_write_dat}' u 1:10 ti 'bs=256k' w lp lt 8, \
      '${curr_write_dat}' u 1:11 ti 'bs=512k' w lp lt 9, \
      '${curr_write_dat}' u 1:12 ti 'bs=1M' w lp lt 10, \
      '${curr_write_dat}' u 1:13 ti 'bs=4M' w lp lt 11, \
      '${curr_write_dat}' u 1:14 ti 'bs=8M' w lp lt 12
iodEOF
  elif [ $var = 'bs' ]; then
    echo "Plotting ${bname_no_ft}.png"
    gnuplot <<- iodEOF
    set terminal pngcairo dashed enhanced size 640,1280
    set output '${1}/png/${bname_no_ft}.png'
    set ylabel '${y_label}'
    set xlabel 'Blocksize'
    set xtic('4k' 1,'8k' 2,'16k' 3,'32k' 4,'64k' 5,'128k' 6,'256k' 7,'512k' 8, \
      '1m' 9,'4m' 10,'8m' 11)
    set multiplot
    set origin 0.0,0.5
    set size 1.0,0.5
    set title "${y_label} in read phase"
    plot \
      '${curr_read_dat}' u 1:4 ti 'iodepth=1' w lp lt 2, \
      '${curr_read_dat}' u 1:5 ti 'iodepth=4' w lp lt 3, \
      '${curr_read_dat}' u 1:6 ti 'iodepth=8' w lp lt 4, \
      '${curr_read_dat}' u 1:7 ti 'iodepth=16' w lp lt 5, \
      '${curr_read_dat}' u 1:8 ti 'iodepth=32' w lp lt 6
    set origin 0.0,0.0
    set size 1.0,0.5
    set title "${y_label} in write phase"
    plot \
      '${curr_write_dat}' u 1:4 ti 'iodepth=1' w lp lt 2, \
      '${curr_write_dat}' u 1:5 ti 'iodepth=4' w lp lt 3, \
      '${curr_write_dat}' u 1:6 ti 'iodepth=8' w lp lt 4, \
      '${curr_write_dat}' u 1:7 ti 'iodepth=16' w lp lt 5, \
      '${curr_write_dat}' u 1:8 ti 'iodepth=32' w lp lt 6
iodEOF
  fi
}

if [ $# -lt 1 ]; then
  echo "ERROR! Usage $0 <data folder>"
  exit
fi

echo "Begin gnuplot processing ..."
if [ -d $1 ]; then
  if [ ! -d "$1/png" ]; then
    echo "Create new folder: $1/png"
    mkdir -p $1/png
  fi

  for file in `ls $1`
  do
    bname=`basename $file`
    rw_mode=${bname%-*}
    format=${bname##*.}
    if [ $format = 'dat' ]; then
      if [ $rw_mode = "rand-randrw" ] || [ $rw_mode = "read-write" ]; then
        echo "FILE NAME: $file"
        gnuPlot2Phase $1 $bname $format
      else
        echo "FILE NAME: $file"
        gnuPlot $1 $bname $format
      fi
    fi
  done
fi
