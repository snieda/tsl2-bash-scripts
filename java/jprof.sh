#!/bin/bash
# Thomas Schneider 08/2020
# Java CLI Profiling with standard java tools
#
# usage: hprof.sh [--init | --help | processname [dumpfile-name]]

#HPROF_CPU=-agentlib:hprof=cpu=samples
#HPROF_HEAP=-agentlib:hprof=heap=dump
JAVA_OPTS="$HPROF_CPU $HPROF_HEAP $JAVA_OPTS"

[ "$1" == "--help" ] || [ "$1" == "" ] && head -n 6 && exit 0
[ "$1" == "--init" ] && echo "hprof set in JAVA_OPTS" && exit 0

PRC=${1:-java}
DUMPFILE=${2:-$PRC.bin}
jmap -dump:live,file=$DUMPFILE $(jps -l | grep $PRC | grep -Eo "^[0-9]+")
jhat $DUMPFILE

