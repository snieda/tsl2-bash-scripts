#!/bin/bash
##############################################################################
# Prüft in der geg. $URL (Seiten 1-4) auf Text $SEARCH 
# Thomas Schneider 09-2020
#
# Aufruf: check-zhs-tennis.sh [date-iso8601] [url] [regex in response]
# 
#   oder alle 5 min: watch -d -b -n 300 ./check-zhs-tennis.sh ...
##############################################################################

[ "$1" == "--help" ] && head -n 9 $0 && exit 1

DATE=${1:-$(date --iso-8601)}
FILE="zhs-tennis-available.html"
URL=${2:-"https://ssl.forumedia.eu/zhs-courtbuchung.de/reservations.php?action=showRevervations&type_id=1&date=$DATE&page="}
PAGES=(1 2 3 4)
SEARCH=${3:-".*avaliable-cell-([2-9]|[0-9]{2}).*1[7-9][:].*"}
OPTS="--silent"
#SCHEDULER="watch -n 120 -x bash -c"

check() {
	echo "check on $DATE for $4"
	for p in {1..4}; do curl $5 $1$p ; done > $2
	grep -e "<title" $2
	echo
	grep -E $4 $2
	[ $? == 0 ] && echo -ne '\007' && echo "---------------> PLATZ GEFUNDEN !!!!"
}
export -f check
# does not work: watch -n 120 check
$SCHEDULER check "$URL" $FILE "$PAGES" "$SEARCH" "$OPTS"

