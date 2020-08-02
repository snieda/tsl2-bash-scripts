#!/bin/bash
# Thomas Schneider 08/2020
# Java CLI Profiling with standard java tools
#
# usage: hprof.sh [--init | --help | processname [dumpfile-name] [hatport]]

#DUMPOVERFLOW=-XX:+HeapDumpOnOutOfMemoryError
#HPROF_CPU=-agentlib:hprof=cpu=samples
#HPROF_HEAP=-agentlib:hprof=heap=dump
JAVA_OPTS="$HPROF_CPU $HPROF_HEAP $JAVA_OPTS $DUMP_OVERFLOW"

for a in "$*" ; do [[ "$a" == *"="* ]] && declare -gt $a && echo $a; done;[ "$1" == "--help" ] || [ "$1" == "" ] && head -n 6 && exit 0
[ "$1" == "--init" ] && echo "hprof set in JAVA_OPTS" && exit 0

for a in "$*" ; do [[ "$a" == *"="* ]] && declare -gt $a && echo $a; done;
PRC=${1:-java}
DUMPFILE=${2:-$PRC-dump.bin}
HATPORT=${3:-7000}

jmap -dump:live,file=$DUMPFILE $(jps -l | grep $PRC | grep -Eo "^[0-9]+")
jhat -port $HATPORT $DUMPFILE

[ "$?" == "0" ] && [ "$(whereis chrome) != "" ] && chrome http://localhost:$HATPORT
