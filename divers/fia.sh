#!/bin/bash
##############################################################################
# find-items-in-all-archives (Thomas Schneider / 2021)
#
# list all files of all archives in all directories of a given basedir
# useful to search for files/classes inside a repository like mavens .m2
#
# usage: fia.sh [basedirs(default:.)] [-r (to reload archives)] [search-txt]
#               [KEY=VALUE,...]
#
# example: fia.sh '~/.m2 $JAVA_HOME/lib' -r 'cover' FUZZY=tee
#
# Note: there are addional variables to be set if default does not fit:
# - ARCHIVES="*.*ar"                   ; *.zip
# - SEARCHER=ag                        ; rg
# - SEARCHER-EXT="*.sources.*ar"       ; 
# - FLIST=.unzip-list.txt              ;
# - FUZZY=fzf                          ; fzy, tee (don't block the terminal)
#
# ag -G ".*-sources.jar" -ilz cover ~/.m2     # zip not supported in ag!!
# rg -g ".*-sources.jar" -ilz cover ~/.m2     # zip not supported in rg!!
##############################################################################

[ "$1" == "--help" ] && head -n 20 $0 && exit 1
echo -en "setting parameters: "; for a in "$*" ; do [[ "$a" == *"="* ]] && declare -gt $a && echo $a; done;

DIRS=${1:-.}
ARCHIVES=${ARCHIVES:-"*.*ar"}
SEARCHER=${SEARCHER:-ag}
SEARCHER_EXT=${SEARCHER_EXT:-"*-sources.*ar"}
FUZZY=${FUZZY:-fzf}
flist=${FLIST:-.unzip-list.txt}

[ "$2" == "-r" ] && [ -f $flist ] && rm -v $flist

if [ "$3" != "" ] && [[ "$3" != *"="* ]]; then
    [ -f $flist ] && rm -v $flist
	echo "searching text $3 in archives in directory $DIRS"
    for d in $DIRS; do for f in $(find $d -name $SEARCHER_EXT); do echo "$f" >> $flist; unzip -p $f | $SEARCHER $3 >> $flist; done; done; cat $flist | $FUZZY
elif [ ! -f $flist ]; then
    echo "searching archives in directory $DIRS"
    for d in $DIRS; do for f in $(find $d -name $ARCHIVES); do echo "$f" >> $flist; unzip -l $f >> $flist; done; done; cat $flist | $FUZZY
else
    echo "loading from existing list: $flist"
    cat $flist | $FUZZY
fi

