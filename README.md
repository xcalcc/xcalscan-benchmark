# Vulnerability Benchmark

## How does this benchmark work
This benchmark contains two kinds of test cases: Single and Multi. Single means the test case only contains 1 source file. The test case name is also the file name without extension. Multi means the test case contains multiple source files. There is a list file to list out all related source files. The test case name is the list file name without '.list' extension. For each test case, there are also master files to capture stdout and stderr. During testing, the tool's output on stdout and stderr will be compared with master stdout and stderr respectively.
If the check and master comparison is OK, the test case will be marked with 'Pass'. Otherwise the test case is 'Fail'. There are 3 failures:
1. The tool failed to check the case, which means the tool returns non-zero after execution.
2. There is no master for the test case.
3. The comparison between tool stdout/stderr and master stdout/stderr failed.


# How to run this benchmark
### Prepare a config file in config directory
For example, tool.cfg with 4 config items:
```
tool: the executable of the tool, which will be executed by driver script.
tool_key: the key of the tool, used in choosing master file to compare.
options: options passed to tool to do SAST scan.
options_key: the key of the options, used in choosing master file to compare.

```

### Once the config file is ready, run driver script with config file name
```
$ ./scripts/driver.sh -c tool.cfg
```

### For xvsa, predefined xvsa.cfg has been added. Run 'run_xvsa.sh' in top directory:
```
$ ./run_xvsa.sh
```

## How to update this benchmark
### How to add a new test set
Run add_testset script with new test set name:
```
$ ./scripts/add_testset.sh DBZ
```

### How to add a new test case
TBD

### How to update test case master files
TBD
