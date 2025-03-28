#!/bin/bash
# do a diff ignoring a given regular expression like a timestamp
# usage: $0 {file1} {file2} [IGNORE=my-regular-expression-to-ignore]
source mainargs.sh $@ || exit 1
FILE1=${FILE1:-$1}
FILE2=${FILE2:-$2}
IGNORE=${IGNORE:-'[0-9]{8}-[0-9]{6}'}
FILTER="sed -r s/$IGNORE/XXX/p"
DIFFER="icdiff -N"
#DRYRUN=printf "%s %s %s "
$DRYRUN $DIFFER <($FILTER $FILE1) <($FILTER $FILE2)