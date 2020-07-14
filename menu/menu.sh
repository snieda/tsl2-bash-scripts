#!/bin/bash
##############################################################################
# provides a simple menu (cp Thomas Schneider 2020)
#
# usage: menu <name> [file-name or wildcard] [-s] [subst=true] [banner=<banner>]
#
# - name        : will be used as variable name and to read the file '$1.lst'
# - file-or-glob: if wildcard, select from file-list, else real file name
# - -s          : simple list separated by spaces
# - subst=true  : variables of your menu list file will be substituted
# - banner=<banner>: use <banner> instead of figlet
#
# - each line has structure: COMMAND # DESCRIPTION
#   with:
#    - COMMAND as any shell command. e.g.: 'menu.sh' for recursion 
#      'read' for input or 'echo' for printing result
#      for complex/unreadable commands, define your own aliases or functions!
#
# - examples:
#    - menu.sh myfile         # will read file myfile.lst as list
#    - menu.sh myfile xyz.sh  # used variable myfile and read list from xyz.sh
#    - menu.sh myfile "*.txt" # select a file from *.txt, result is in $myfile
#
# NOTE: 
#    - if figlet is installed, an ascii title will be printed
#    - if the file 'menu-alias.sh' was found it will be loaded
#    - finally, the file 'menu-$USERNAME.sh' with results will be created
##############################################################################

BANNER=<<EOF
 __  __                  
|  \/  | ___ _ __  _   _ 
| |\/| |/ _ \ '_ \| | | |
| |  | |  __/ | | | |_| |
|_|  |_|\___|_| |_|\__,_|
                         
EOF

[ "$1" == "" ] && head -n 28 $0 && exit 1
for a in "$*" ; do declare -gt $a; echo $a; done;

[ -e menu-alias.sh ] && source menu-alias.sh
[ -e menu-defaults.def ] && source menu-defaults.def
[ -e menu-$USERNAME.def ] && source menu-$USERNAME.def

run() { source $*; }
edit() { read -ep "$1: " -i $1 edit; declare -xt $1=$edit; NAME=$1; CMD=$edit; } 
choose() { source menu.sh $1 "$2" "$3"; }
bar__() { for i in {1..26}; do printf "%s" $1; done; }
printbar() { printf "$C_FRM<"; bar__ "-"; printf "|%14s%-14s|" $1 $2; bar__ "-"; printf ">%s$R" $'\n'; }
setcolors() { echo "$1" | sed -nEe "s/(\w+)(.*)([#].*)/$C_CMD\1$C_PAR\2$C_CMT\3$R/p"; }

NAME=$1
case $2 in *[*]*) LIST=$2;; *[.]*) LIST=$(< $2);; *) LIST=$(< $NAME.lst) ;; esac
[ "$subst" == "true" ] && LIST=$(printf "$LIST" | envsubst "$(set -o posix; set)")
LIST=$(setcolors "$LIST")
IFS_=$IFS
[ "$2" != "-s" ] && [ "$3" != "-s" ] && IFS=$'\n'
PS3="$(printbar "PLEASE SELECT" " 1..$(echo "$LIST" | wc -l)") "$'\n'": "

banner=${banner:-figlet}
ascii_banner_installed=$(which $banner) # on cygwin, 'which' prints always the path
#clear
echo -en $LYELLOW
if [ "$ascii_banner_installed" != "" ]; then $banner "$NAME"; else head -n 36 $0 | tail -n 6; fi
printbar "PLEASE SELECT" " $NAME"
select i in $LIST ; do 
	[ "$i" == "" ] || [ "$i" == "0" ] && break
	IFS=$IFS_
	CMD=${i%#*}
	echo $CMD
	[ "$CMD" != "" ] && declare -tx $NAME="$CMD";
	eval "$CMD"
done
echo "$NAME=$CMD" >> menu-$USERNAME.sh
printbar "$NAME: " "$CMD"
