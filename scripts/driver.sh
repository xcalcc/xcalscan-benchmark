#!/bin/sh
#
# Copyright (C) 2022 Xcalibyte www.xcalibyte.com
#

# driver for this benchmark

self_name=`basename $0`
work_dir=`pwd`

# USAGE: function to display usage
USAGE() {
  echo "Setup test environment and run benchmark"
  echo "Usage:"
  echo "  $self_name -c cfg_file [-t test_set[,test_set]] [-s single|multi] [-o out_dir] [-v]"
  echo "    -c cfg_file: specify config file name"
  echo "    -t test_set[,test_set]: specify test sets to be tested"
  echo "    -s single|multi: only test single or multi source file cases"
  echo "    -o out_dir: specify output directory. default is out.<tool_key>"
  echo "    -v: output verbose message"
  echo "  config file:"
  echo "    config file is written in shell script syntax to speficy tool, tool_key,"
  echo "    options and options_key"
  echo "    config file must be in config directory"
  echo ""
  echo "Example:"
  echo "  $self_name -c xvsa.cfg -r NPD,AOB"
  echo "    test xvsa with NPD and AOB test sets"
  echo "  $self_name -c xvsa.cfg -s single"
  echo "    test xvsa with all single source file test cases"
  echo "  $self_name -c xvsa.cfg -o my_result"
  echo "    test xvsa with all test cases and use my_result as output directory"
}

# check parameters
config_file=
test_sets=
sub_tests=
out_dir=
verbose=0

while [ $# -ne 0 ]; do
  opt_key="$1"
  case "$opt_key" in
  "-c" )
    shift
    config_file="$1"
    ;;
  "-t" )
    shift
    test_sets="$1"
    ;;
  "-s" )
    shift
    sub_tests="$1"
    ;;
  "-o" )
    shift
    out_dir="$1"
    ;;
  "-v" )
    verbose=1
    ;;
  * )
    USAGE
    echo "Error: unknown parameter $1"
    exit 1
    ;;
  esac
  if [ $# -eq 0 ]; then
    USAGE
    echo "Error: no value for parameter '$opt_key'"
    exit 1
  fi
  shift
done

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

# check directory
if [ ! -d "$work_dir/benchmark" -o \
     ! -d "$work_dir/scripts" -o \
     ! -f "$work_dir/scripts/$self_name" ]; then
  USAGE
  echo "Error: run the script in benchmark top directory"
  exit 1
fi

# check config file
if [ ! -f "$work_dir/config/$config_file"  ]; then
  USAGE
  echo "Error: not find config file: config/$config_file"
  exit 1
fi

# import config file
# GET_CONF_VALUE: function to get value from config gile
GET_CONF_VALUE() {
  grep "^[[:space:]]*$2=" "$work_dir/config/$1" | sed -e "s/.*$2=//g"
}

tool_key=`GET_CONF_VALUE $config_file tool_key`
tool=`GET_CONF_VALUE $config_file tool`
options_key=`GET_CONF_VALUE $config_file options_key`
options=`GET_CONF_VALUE $config_file options`

if [ x"$tool" = x ]; then
  USAGE
  echo "Error: no tool found in config/$config_file"
  exit 1
fi

if [ x"$tool_key" = x ]; then
  tool_key="$tool"
fi

# handle test_sets
if [ x"$test_sets" = x ]; then
  for dirn in `ls $work_dir/benchmark`; do
    if [ -d $work_dir/benchmark/$dirn/Master ]; then
      test_sets="$test_sets $dirn"
    fi
  done
else
  test_sets="`echo $test_sets | sed -e 's/,/ /g'`"
fi

# check output dir
if [ x"$out_dir" = x ]; then
  if [ x"$options_key" != x ]; then
    out_dir="out.$tool_key.$options_key"
  else
    out_dir="out.$tool_key"
  fi
fi

# make output directory
if [ -d "$work_dir/$out_dir" ]; then
  echo "Warning: output directory $out_dir exists. Try to remove it"
  rm -r "$work_dir/$out_dir"
fi
mkdir "$work_dir/$out_dir"

# global counters
total_pass=0
check_fail=0
nomaster_fail=0
diff_fail=0

# log files
log_file="$work_dir/$out_dir/test.log"
result_file="$work_dir/$out_dir/result.log"

# OUTPUT_LOG: function to output log message
OUTPUT_LOG() {
  echo "$*"
  time=`date '+%Y-%m-%d %H:%M:%S.%N'`
  echo "$time $*" >> "$log_file"
}

# OUTPUT_VERBOSE: function to output verbose message
OUTPUT_VERBOSE() {
  if [ $verbose -eq 1 ]; then
    echo "$*"
  fi
  time=`date '+%Y-%m-%d %H:%M:%S.%N'`
  echo "$time $*" >> "$log_file"
}

# TEST_SET: function to run single test in one test_set
TEST_SET() {
  # set sub_dir from $1
  sub_dir="$1"
  sub_test="$2"

  # initialize local counters
  pass=0
  fail_1=0
  fail_2=0
  fail_3=0

  # counting files
  if [ "$sub_test" = "Single" ]; then
    file_list=`ls "$work_dir/benchmark/$sub_dir/Single" --hide=README.md 2>/dev/null`
    file_cnt=`ls "$work_dir/benchmark/$sub_dir/Single" --hide=README.md 2>/dev/null | wc -l`
  elif [ "$sub_test" = "Multi" ]; then
    file_list=`ls $work_dir/benchmark/$sub_dir/Multi/*.list 2>/dev/null`
    file_cnt=`ls $work_dir/benchmark/$sub_dir/Multi/*.list 2>/dev/null | wc -l`
  else
    return
  fi

  # start test
  OUTPUT_LOG "Start testing $sub_dir/$sub_test test cases: $file_cnt"
  CHECK mkdir -p "$work_dir/$out_dir/$sub_dir/$sub_test"
  cd "$work_dir/$out_dir/$sub_dir/$sub_test"

  counter=0
  for f in $file_list; do
    # only keep file name
    f=`basename $f`

    # ignore README
    if [ x"$f" = xREADME.md ]; then
      continue;
    fi

    counter=`expr "$counter" '+' 1`
    test_case_name="${f%.*}"

    # get real file list for multi
    if [ $sub_test = Multi ]; then
      input=
      for i in `cat $work_dir/benchmark/$sub_dir/$sub_test/$f`; do
        input="$input $work_dir/benchmark/$sub_dir/$sub_test/$i"
      done
    else
      input="$work_dir/benchmark/$sub_dir/$sub_test/$f"
    fi

    # exec the tool
    OUTPUT_VERBOSE "    ($counter/$file_cnt) EXEC: $tool $options $input"
    $tool $options $input 1>$test_case_name.out 2>$test_case_name.err
    ret=$?
    if [ $ret -ne 0 ]; then
      fail_1=`expr "$fail_1" '+' 1`
      OUTPUT_VERBOSE "    ($counter/$file_cnt) FAIL: check $f returns $ret"
      continue;
    fi

    # find master files
    master_out="$work_dir/benchmark/$sub_dir/Master/$test_case_name.$tool_key.$options_key.out"
    if [ ! -f "$master_out" ]; then
      master_out="$work_dir/benchmark/$sub_dir/Master/$test_case_name.$tool_key.out"
    fi
    master_err="$work_dir/benchmark/$sub_dir/Master/$test_case_name.$tool_key.$options_key.err"
    if [ ! -f "$master_err" ]; then
      master_err="$work_dir/benchmark/$sub_dir/Master/$test_case_name.$tool_key.err"
    fi
    if [ ! -f "$master_out" -a ! -f "$master_err" ]; then
      fail_2=`expr "$fail_2" '+' 1`
      if [ x"$options_key" = x ]; then
        OUTPUT_VERBOSE "    ($counter/$file_cnt) FAIL: no master file $test_case_name.$tool_key.out or $test_case_name.$tool_key.err"
      else
        OUTPUT_VERBOSE "    ($counter/$file_cnt) FAIL: no master file $test_case_name.$tool_key.$options_key.out or $test_case_name.$tool_key.out or $test_case_name.$tool_key.$options_key.err or $test_case_name.$tool_key.err"
      fi
      continue;
    fi

    # diff with master files
    if [ -f "$master_out" ]; then
      diff "$master_out" "$test_case_name.out" >/dev/null 2>&1
      if [ $? -ne 0 ]; then
        fail_3=`expr "$fail_3" '+' 1`
        OUTPUT_VERBOSE "    ($counter/$file_cnt) FAIL: stdout is different from benchmark/$sub_dir/Master/`basename $master_out`"
        continue;
      fi
    fi
    if [ -f "$master_err" ]; then
      diff "$master_err" "$test_case_name.err" >/dev/null 2>&1
      if [ $? -ne 0 ]; then
        fail_3=`expr "$fail_3" '+' 1`
        OUTPUT_VERBOSE "    ($counter/$file_cnt) FAIL: stderr is different from benchmark/$sub_dir/Master/`basename $master_err`"
        continue;
      fi
    fi

    # increase pass counter
    pass=`expr "$pass" '+' 1`
    OUTPUT_VERBOSE "    ($counter/$file_cnt) PASS: $test_case_name"
  done
  cd "$work_dir"

  # finish test
  OUTPUT_LOG "Finish testing $sub_dir/$sub_test test cases"
  OUTPUT_LOG "    Total Pass:  \t$pass"
  OUTPUT_LOG "    Check Fail:  \t$fail_1"
  OUTPUT_LOG "    No Master:   \t$fail_2"
  OUTPUT_LOG "    Master Diff: \t$fail_3"
  total_pass=`expr "$total_pass" '+' "$pass"`
  check_fail=`expr "$check_fail" '+' "$fail_1"`
  nomaster_fail=`expr "$nomaster_fail" '+' "$fail_2"`
  diff_fail=`expr "$diff_fail" '+' "$fail_3"`
}

# start test
OUTPUT_LOG "Start Xcalscan Benchmark Testing"
OUTPUT_VERBOSE "Tool: $tool"
OUTPUT_VERBOSE "Options: $options"
OUTPUT_VERBOSE "Selected test sets: $test_sets"
OUTPUT_VERBOSE "Selected sub tests: $sub_tests"

# start timer
time_start=`date +%s`

for sub_dir in $test_sets; do
  # run single test
  if [ -d "$work_dir/benchmark/$sub_dir/Single" -a \
       x"$sub_tests" != "multi" ]; then
    TEST_SET "$sub_dir" Single
  fi

  # run multi test
  if [ -d "$work_dir/benchmark/$sub_dir/Multi" -a \
       x"$sub_tests" != "single" ]; then
    TEST_SET "$sub_dir" Multi
  fi
done
sleep 1
# end timer
time_end=`date +%s`
time_used=`expr $time_end '-' $time_start`

OUTPUT_LOG "Finish Xcalscan Benchmark Testing"
OUTPUT_LOG "    Total  Pass:  \t$total_pass"
OUTPUT_LOG "    Check  Fail:  \t$check_fail"
OUTPUT_LOG "    No Master:    \t$nomaster_fail"
OUTPUT_LOG "    Master Diff:  \t$diff_fail"
OUTPUT_LOG "    Time Elapsed: \t$time_used seconds"
