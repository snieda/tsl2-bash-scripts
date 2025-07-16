#!/bin/bash
##############################################################################
# Searches through a loop of pages, given by $URL and $LOOP for a given text
# Thomas Schneider 09-2020
#
# usage: checkurl.sh [--help | [date-iso8601] [url] [regex in response]]
# 
#   or all 5 min: watch -d -b -n 300 ./checkurl.sh ...
#
# Example:
#   watch -db -n 300 ./checkurl.sh 2020-09-05
# NOTE: for sound mit 'play', please call 'pkg install sox'
##############################################################################

[ "$1" == "--help" ] && head -n 12 "$0" && exit 1

PRG="curl"
DATE=${1:-$(date --iso-8601)}
FILE="checkurl-response.html"
# for the for loop - use the loop variable $VAR in your url to loop through different pages
VAR='$VAR'
LOOP=(1 2 3 4)

# be careful: on urls the & has to be surrounded by ': '&'
URL=${2:-"https://zhs-courtbuchung.de/reservations.php?action=showRevervations'&'type_id=1'&'date=$DATE'&'page=$VAR"}
FILTER='[<]title.*[>](.*).*'
SEARCH=${3:-'.*avaliable-cell-([2-9]|[0-9]{2}).*1[7-9][:][03]{2} [-].*'}
OPTS=${4:-"--silent"}
PLAYSOUND=${PLAYSOUND:-'play -q -n synth 0.1 sin 880 ; echo -ne \007'}
#SCHEDULER="watch -b -d -n 120 -x bash -c"

check() {
	echo "check on $DATE for loop $4 searching for: $5"
	for VAR in $4; do $PRG "$6" $(eval echo "$1") ; done > $2
	sed -nEe "s/$3/\\1/p" "$2" && echo && grep -E "$5" "$2"
	[ $? == 0 ] && eval $PLAYSOUND && echo "---------------> ENTRY FOUND !!!!"
}
export -f check
# does not work: watch -n 120 check
$SCHEDULER check "$URL" "$FILE" "$FILTER" "${LOOP[*]}" "$SEARCH" "$OPTS"
