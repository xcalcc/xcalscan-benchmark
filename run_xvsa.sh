#!/bin/sh

# check directory
work_dir=`pwd`
if [ ! -d "$work_dir/benchmark" -o \
     ! -d "$work_dir/scripts" -o \
     ! -f "$work_dir/scripts/driver.sh" ]; then
  echo "Error: run the script in benchmark top directory"
  exit 1
fi

# check xvsa
xvsa=`grep "^[[:space:]]*tool=" config/xvsa.cfg | sed -e "s/.*tool=//g"`
if [ ! -e "$xvsa" ]; then
  xvsa=`which $xvsa`
  if [ ! -e "$xvsa" ]; then
    echo "Error: not find xvsa in \$PATH. Add xvsa to \$PATH or modify 'tool' in config/xvsa.cfg to full path name."
    exit 1
  fi
fi

# run benchmark
./scripts/driver.sh -c xvsa.cfg
