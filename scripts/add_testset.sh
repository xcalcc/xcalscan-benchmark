#!/bin/sh
#
# Copyright (C) 2022 Xcalibyte www.xcalibyte.com
#

# script to add new test sets

self_name=`basename $0`
work_dir=`pwd`

# USAGE: function to display usage
USAGE() {
  echo "Add test set and setup directories for new test set"
  echo "Usage:"
  echo "  $self_name test_set1 [ test_set2 ... ]"
  echo "    test_set1: name of the test set"
  echo ""
  echo "Example:"
  echo "  $self_name AOB NPD"
} 

# check parameters
if [ x"$1" = x -o "$1" = "-h" -o "$1" = "--help" ]; then
  USAGE
  exit 0
fi

# check working directory
if [ ! -d "$work_dir/benchmark" -o \
     ! -d "$work_dir/scripts" -o \
     ! -f "$work_dir/scripts/$self_name" ]; then
  USAGE
  echo "Error: run the script in benchmark top directory"
  exit 1
fi

# CHECK: function to run commands and check return value
CHECK() {
  cmd="$1"
  shift
  "$cmd" "$@"
  ret=$?
  if [ $ret -ne 0 ]; then
    echo "Error: run $cmd failed. retval=$ret"
    echo "       $cmd $@"
    exit 1
  fi
}

# GEN_MASTER_README: function to generate README for Master
GEN_MASTER_README() {
  cat >$work_dir/benchmark/$1/Master/README.md << EOF
README
--------
This folder contains master files for $1.

For each test case, there are 2 master files, one for stdout and the other
for stderr.  The file name of master files follows the convention below:
<test_case_name>.<tool>.<options>.out
<test_case_name>.<tool>.<options>.err

If no options needed, the following file names are used:
<test_case_name>.<tool>.out
<test_case_name>.<tool>.err

EOF
}

# GEN_SINGLE_README: function to generate README for test case with single
# source file
GEN_SINGLE_README() {
  cat >$work_dir/benchmark/$1/Single/README.md << EOF
README
--------
This folder contains test case for $1 with single source file.

The single test case file name is made up of <test_case_name> with extension
which can be c, C, cc, cpp or cxx:
<test_case_name>.<ext_name>

The test driver will check all source files one-by-one with given options.
Compare stdout and stderr with files named <test_case_name>.<tool>.<options>.out
and <test_case_name>.<tool>.<options>.err in Master directory respectively.

To add a new single file test file, add the source file into Single directory
and expected out/err files into Master directory.

EOF
}

# GEN_MULTI_README: function to generate README for test case with multiple
# source file
GEN_MULTI_README() {
  cat >$work_dir/benchmark/$1/Multi/README.md << EOF
README
--------
This folder contains test case for $1 with multiple source files.

Each test case in Multi contains a list file and several source files.
The list file name must be:
<test_case_name>.list

The <test_case_name> should *NOT* be duplicated with test case in Single
directory. The source file names are listed in the list file. There is no
convention on source file names but it should be with good readability and
maintainability and no duplication.

For example:
$ cat test-case1.list
test-case1-1.c test-case1-2.c test-case1-3.c
$ ls test-case1-1.c test-case1-2.c test-case1-3.c
test-case1-1.c test-case1-2.c test-case1-3.c

The test driver will check all list files and pass the source files in list
file to SAST tool at the same time. The stdout and stderr will be compared
with <test_case_name>.<tool>.<options>.out and <test_case_name>.<tool>.<options>.err
in Master directory respectively.

EOF
}

# process each test set
while [ $# -ne 0 ]; do
  tsname="$1"
  shift
  if [ -d "$work_dir/benchmark/$tsname" ]; then
    echo "Warning: ignore existing test set $tsname"
    continue
  fi
  # create directory for master files
  CHECK mkdir -p $work_dir/benchmark/$tsname/Master
  # create directory for test case with single source file
  CHECK mkdir -p $work_dir/benchmark/$tsname/Single
  # create directory for test case with multiple source files
  CHECK mkdir -p $work_dir/benchmark/$tsname/Multi

  # create README.md file in each directory
  GEN_MASTER_README $tsname
  GEN_SINGLE_README $tsname
  GEN_MULTI_README  $tsname
done

exit 0
