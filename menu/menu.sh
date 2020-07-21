#!/bin/bash
##############################################################################
# provides a simple menu (cp Thomas Schneider 2020)
#
# usage: menu <name> [file-name or wildcard] [-s] [subst=true] [BANNER=<banner>]
#             [EDITOR=<editor>] [reset=<clear>] [export=true]
# - name        : will be used as variable name and to read the file '$1.lst'
# - file-or-glob: if wildcard, select from file-list, else menu file name
# - -s          : simple list separated by spaces
# - subst=true  : variables of your menu list file will be substituted
# - BANNER=<banner>: use <banner> instead of figlet
# - EDITOR=<editor>: use <editor> instead of vim
# - reset=<clear>  : use output instead of clear
# - export=true    : the content of menu-defaults.def and menu-$USERNAME.def
#                    will be exported (may cause problems...)
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
# you may use the folowing convenience methods in your menu list file:
#    editor, choose, edit, show, run
# NOTE: 
#    - if figlet is installed, an ascii title will be printed
#    - if the file 'menu-alias.sh' was found it will be loaded
#    - finally, the file 'menu-$USERNAME.sh' with results will be created
##############################################################################

title=<<EOF
 __  __                  
|  \/  | ___ _ __  _   _ 
| |\/| |/ _ \ '_ \| | | |
| |  | |  __/ | | | |_| |
|_|  |_|\___|_| |_|\__,_|
                         
EOF

[ "$1" == "" ] && head -n 34 $0 && exit 1
for a in "$*" ; do [ "$a" == *"="* ] && declare -gt $a; echo $a; done;

[ -e menu-alias.sh ] && source menu-alias.sh
[ -e menu-defaults.def ] && [ "$export" == "true" ] && (export $(xargs <menu-defaults.def) || source menu-defaults.def)
[ -e menu-$USERNAME.def ] && [ "$export" == "true" ] && (export $(xargs <menu-$USERNAME.def) || source menu-$USERNAME.def)

run() { bash $1 $2 $3; }
input() { read -ep ": " -i "${!1}" edt; declare -g $1=$edt; echo "$1=$edt" >> menu-$USERNAME.def; } 
choose() { bash menu.sh "$@"; }
edit() { ${EDITOR:-vim} "$*"; }
show() { echo "$@"; }

bar__() { for i in {1..26}; do printf "%s" $1; done; }
printbar() { printf "$C_FRM<"; bar__ "-"; printf "|%14s%-14s|" $1 $2; bar__ "-"; printf ">%s$R" $'\n'; }
setcolors() { echo "$1" | sed -nEe "s/(\w+|[#-]+)(.*)(([#]|[-]{2}).*)/$C_CMD\1$C_PAR\2$C_CMT\3$R/p"; }

menu_main() { 
	NAME=$1
	IFS_=$IFS
	# declare RUNLINE="true"

	case $2 in *[*]*) LIST=$2;; *[.]*) LIST=$(< $2);; *) LIST=$(< $NAME.lst) ;; esac
	[ "$subst" == "true" ] && LIST=$(printf "$LIST" | envsubst "$(set -o posix; set)")
	[ "$2" != "-s" ] && [ "$3" != "-s" ] && [[ "$2" != *"*"* ]] && RUNLINE="true" && IFS=$'\n' && LIST=$(setcolors "$LIST") || RUNLINE="false"
	PS3="$(printbar "PLEASE SELECT" " 1..$(echo "$LIST" | wc -l)") "$'\n'": "

	BANNER=${BANNER:-figlet}
	ascii_banner_installed=$(which $BANNER) # on cygwin, 'which' prints always the path
	${reset:-clear}
	echo -en $LYELLOW
	if [ "$ascii_banner_installed" != "" ]; then $BANNER "$NAME"; else head -n 42 $0 | tail -n 6; fi
	printbar "PLEASE SELECT" " $NAME"
	select i in $LIST ; do 
		[ "$i" == "" ] || [ "$i" == "0" ] && break
		IFS=$IFS_
		CMD=${i%#*}
		CMD=$(echo "$CMD" | sed 's/\x1b\[[0-9;]*m//g')
		echo -en $C_FRM$CMD$R
		[ "$CMD" != "" ] && declare -x $NAME="$CMD";
		[ "$RUNLINE" == "true" ] && eval "$CMD"
	done
	echo "$NAME=$CMD" >> menu-$USERNAME.def
	printbar "$NAME: " "$CMD"
}

menu_main "$@"
