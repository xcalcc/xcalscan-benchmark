README
--------
This folder contains test case for NPD with multiple source files.

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
with <test_case_name>.<options>.out and <test_case_name>.<options>.err in
Master directory respectively.

