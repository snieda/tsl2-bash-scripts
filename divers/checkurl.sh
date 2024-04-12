#!/bin/bash
##############################################################################
# Prüft in der geg. $URL (Seiten 1-4) auf Text $SEARCH 
# Thomas Schneider 09-2020
#
# Aufruf: checkurl.sh [--help | [date-iso8601] [url] [regex in response]]
# 
#   oder alle 5 min: watch -d -b -n 300 ./checkurl.sh ...
#
# Beispiel:
#   watch -db -n 300 ./checkurl.sh 2020-09-05
##############################################################################

[ "$1" == "--help" ] && head -n 12 "$0" && exit 1

DATE=${1:-$(date --iso-8601)}
FILE="checkurl-response.html"
URL=${2:-"https://ssl.forumedia.eu/zhs-courtbuchung.de/reservations.php?action=showRevervations&type_id=1&date=$DATE&page="}
PAGES=(1 2 3 4)
SEARCH=${3:-'.*avaliable-cell-([2-9]|[0-9]{2}).*1[7-9][:][03]{2} [-].*'}
OPTS="--silent"
#SCHEDULER="watch -b -d -n 120 -x bash -c"

check() {
	echo "check on $DATE for $4"
	for p in $3; do curl "$5" "$1$p" ; done > "$2"
	#grep -e "<title" $2
	#sed -nEe "s/[<]title.*[>](.*)[<][/]title.*/\1/p" $2
	sed -nEe "s/[<]title.*[>](.*).*/\\1/p" "$2"
	echo
	grep -E "$4" "$2"
	[ $? == 0 ] && echo -ne '\007' && echo "---------------> PLATZ GEFUNDEN !!!!"
}
export -f check
# does not work: watch -n 120 check
$SCHEDULER check "$URL" "$FILE" "${PAGES[*]}" "$SEARCH" "$OPTS"
