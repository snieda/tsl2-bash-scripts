#!/bin/bash
##############################################################################
# provides a simple menu (cp Thomas Schneider 2020)
#
# usage: menu <name> [file-name or wildcard] [-s]
#
# - name        : will be used as variable name and to read the file '$1.csv'
# - file-or-glob: if wildcard, select from file-list, else real file name
# - -s          : simple list separated by spaces
#
# - each line has structure: COMMAND # DESCRIPTION
#   with:
#    - COMMAND as any shell command. e.g.: 'menu.sh' for recursion 
#      'read' for input or 'echo' for printing result
#      for complex/unreadable commands, define your own aliases or functions!
#
# - examples:
#    - menu.sh myfile         # will read file myfile.csv as list
#    - menu.sh myfile xyz.sh  # used variable myfile and read list from xyz.sh
#    - menu.sh myfile "*.txt" # select a file from *.txt, result is in $myfile
##############################################################################

[ "$1" == "" ] && head -n 21 $0 && exit 1
for a in "$*" ; do declare -gt $a; echo $a; done;

[ -e menu-alias.sh ] && source menu-alias.sh

edit() { read -ep "$1: " -i $1 edit; declare -xt $1=$edit; } 
choose() { source menu.sh $1 "$2"; }

NAME=$1
case $2 in *[*]*) LIST=$2;; *[.]*) LIST=$(< $2);; *) LIST=$(< $NAME.csv);; esac
IFS_=$IFS
[ "$3" != "-s" ] && IFS=$'\n'
PS3="\\--------------------| PLEASE SELECT 1..$($LIST | wc -l) |------------------------------/"$'\n'": "

clear
echo "/--------------------| PLEASE SELECT $NAME |---------------------------------\\"
select i in $LIST ; do 
	[ "$i" == "" ] || [ "$i" == "0" ] && break
	IFS=$IFS_
	CMD=${i%#*}
	echo $CMD
	[ "$CMD" != "" ] && declare -tx $NAME="$CMD";
	eval "$CMD"
done
echo "/-------------------------| $NAME: $CMD |--------------------------------------\\"

