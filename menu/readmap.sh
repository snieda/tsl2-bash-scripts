#!/bin/bash
##############################################################################
# readmap.sh (Thomas Schneider 2020)
# 
# maps all key/values read from given map file (first 2 lines reserved for header)
#
# usage: $0 <map-file> []map-name] [-quiet]
# arguments:
#   1: map file (e.g.: process.map)
#   2: map name (e.g.: values)
#   3: -quiet   (optional, if set, map will not be echoed)
# use:
#   source readmap.sh birthdays.map birthday 
#   getbirthday "michael"
#
# example map: birthdays.map:
# Name           Birthday
# |-------------|--------|
# michael       10-10-2000
# stefan        09-09-1995
##############################################################################

# help
[ "$1" == "--help" ] || [ "$1" == "" ] && head -n21 $0 && exit 0

# definitions
MAPFILE=${1:-values.map}    # map file path

# standard functions
getfilename () {
    filename=$(basename -- "$1")
    extension="${filename##*.}"
    filename="${filename%.*}"   
    echo "$filename"
}

MAPNAME=$(getfilename $MAPFILE) # name for array holding the map
declare -A MAP
foreachitem() { for i in ${!MAP[@]} ; do $1 $i ${MAP["$i"]}; done;}

# dynamic functions (we have to escape variables in the body!)
VAL=${2:-val}               # name for the items value
source /dev/stdin <<EOF
get$VAL () { echo \${MAP[\$1]} ;}
EOF

# main
echo "reading map from: '$MAPFILE' into array: 'MAP'"
while read -r key value; do MAP[$key]=$value; done < <(tail -n +3 $MAPFILE)

echo "access method is: get$VAL"
[ "$3" != "-quiet" ] && foreachitem "echo"


