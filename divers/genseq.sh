#!/bin/bash
# generates a csv file through a given column-array and seqences of type words, numbers and dates
# (cr) Thomas Schneider
#
# usage genseq.sh name {outer-array-sequence[::inner-array-sequence]...}
# with array-sequence:
#   - dates from to step     # with start,end: date or 'today' or [+][0-9]+, step: day, month, year
#   - lines(filename)        # with reading lines of filename
#   - seq{start,step,end}    # with all numbers between start and end
#
# examples:
#   genseq.sh genseq-test.csv  "numbers 11 1 12" "dates 2025-01-01 2025-12-01 month"
#   genseq.sh genseq-test.csv "lines test-lines.txt" "dates today 2025-07-25 day"  "numbers 1 1 4"  "numbers 1 1 4"
#   genseq.sh genseq-test.csv "dates today +7 year"
#
# notes:
#   may be used together with reqs.sh
##############################################################################

dates() {
    from=$1
    until=$2
    step=$3
    [[ "$from" == "today" ]] && from=$(date -I)
    [[ "$until" == "today" ]] && until=$(date -I)
    [[ "$step" == "" ]] && step="day"
    [[ "$until" =~ [+-][0-9]+ ]] && until=$(date -I -d "$from $until $step")
    cur=$from
    while read line; do
        cur=$from
        while [[ ! "$cur" > "$until" ]]; do
            echo -en "${line[@]}$sep$cur\n" >> $outputfile.tmp
            cur=$(date -I -d "$cur + 1 $step")
        done
    done <$outputfile
    mv -f $outputfile.tmp $outputfile
}

lines() {
    while read line; do
        while read l ; do echo -en "${line[@]}$sep${l[@]}\n" >> $outputfile.tmp ; done <$1
    done <$outputfile
    mv -f $outputfile.tmp $outputfile
}

numbers() {
    while read line; do
        for n in $(seq $1 $2 $3) ; do echo -en "${line[@]}$sep$n\n" >> $outputfile.tmp ; done
    done <$outputfile
    mv -f $outputfile.tmp $outputfile
}

outputfile=$1;shift
sep='\t'
# to have at least one line at start...
echo " " > $outputfile

for a in "$@" ; do echo "running $a ..."; $a ; done

sed -i "1 i\# generated file through \"genseq.sh $@\"" $outputfile
