#!/bin/bash
./branchless-fizzbuzz >test.txt

if cmp -s expected.txt test.txt; then
    echo "no regression"
else
    echo "regression!"
fi
