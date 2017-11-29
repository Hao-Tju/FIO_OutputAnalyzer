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
  y_label='lalal'

  echo "Now is processing $2"
  if [ $y_axis = 'lat' ]; then
    y_label="Latency(usec)"
  elif [ $y_axis = 'IOPS' ]; then
    y_label='IOPS'
  elif [ $y_axis = 'avg_bw' ]; then
    y_label='Average Bandwidth (MiB/s)'
  fi

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

  echo "Now is processing $2"
  if [ $y_axis = 'lat' ]; then
    y_label="Latency(usec)"
  elif [ $y_axis = 'IOPS' ]; then
    y_label='IOPS'
  elif [ $y_axis = 'avg_bw' ]; then
    y_label='Average Bandwidth (MiB/s)'
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
