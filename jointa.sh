#! /bin/bash

gawk -f script.awk $(ls -v Pi*.txt) > output.txt
# Output is space-delimited.

# Order in which the files were merged.
ls -v Pi*.txt > processorder.txt