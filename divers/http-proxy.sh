#!/bin/bash
#-----------------------------------------------------------------------------
# simple http proxy through netcat (Thomas Schneider 2020)
#
# usage: $0 <dest-host> [dest-port (default:80)] [src-port (default: 8888)] 
#           [ncopt=<netcat options>]
#-----------------------------------------------------------------------------

[ $# == 0 ] || [ "$1" == "--help" ] && head -n 7 $0 && exit 1
echo -en "setting parameters: "; for a in "$*" ; do [[ "$a" == *"="* ]] && declare -gt $a && echo $a && shift; done;
echo

DEST=$1 DEST_PORT=${2:-80} PORT=${3:-8888}
TMP=`mktemp -d`
BACK=$TMP/pipe.back
SENT=$TMP/pipe.sent
RCVD=$TMP/pipe.rcvd
#trap 'rm -rf "$TMP"' EXIT
mkfifo -m 0600 "$BACK" "$SENT" "$RCVD"
sed 's/^/=> /' <"$SENT" &
sed 's/^/  <= /' <"$RCVD" &
echo "listening on $PORT"
echo "use curl -x localhost:$PORT or set shell vars http(s)_port to use as proxy!"
nc $ncopt -k -l -p "$PORT" <"$BACK" | tee "$SENT" | nc $ncopt "$DEST" "$DEST_PORT" | tee "$RCVD" >"$BACK"
