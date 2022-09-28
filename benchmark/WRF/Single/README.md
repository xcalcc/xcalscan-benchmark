README
--------
This folder contains test case for WRF with single source file.

The single test case file name is made up of <test_case_name> with extension
which can be c, C, cc, cpp or cxx:
<test_case_name>.<ext_name>

The test driver will check all source files one-by-one with given options.
Compare stdout and stderr with files named <test_case_name>.<options>.out and
<test_case_name>.<options>.err in Master directory respectively.

To add a new single file test file, add the source file into Single directory
and expected out/err files into Master directory.

