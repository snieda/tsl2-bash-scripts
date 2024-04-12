#!/bin/bash
#-----------------------------------------------------------------------------
# simple http proxy through netcat (Thomas Schneider 2020)
#
# usage: $0 [proxy-port (default: 8888)] [sendsed=<my-sed-expr>] [recvsed=<<my-sed-expr>]
#           [ncopt=<netcat options>]
#-----------------------------------------------------------------------------

[ "$1" == "--help" ] && head -n 7 $0 && exit 1
echo -en "setting parameters: "; for a in "$*" ; do [[ "$a" == *"="* ]] && declare -gt $a && echo $a && shift; done;
echo

set -x
nc="pwncat -v" # perhaps you want to use ncat or pwncat
PORT=${1:-9999}
sendsed=${sendsed:-s///}
recvsed=${recvsed:-s///}
rm fifo sent
mkfifo fifo sent

response_loop() {
  echo "starting proxy loop"
  while true; do
    if read -r line <sent; then
      echo "$line"
      echo $line | $nc -v $(geturl $line) | tee fifo
    fi
  done
}

request_loop() {
  echo "starting response loop"
  while true; do
    if read -r line <sent; then
      echo "$line"
      echo $line | $nc $ncopt -v -l $PORT < fifo | tee | tee sent &
   fi
  done
}

geturl() {
    cut "$1" -d ' ' -f 2
}

echo "listening on $PORT    (use curl -x localhost:$PORT or set shell vars http(s)_port to use as proxy!)"
#$nc $ncopt -k -l $PORT < fifo | tee | tee sent | sed -e $sendsed | call | tee | sed -e $recvsed > fifo

# start the proxy
#$nc $ncopt -v -k -l $PORT < fifo | tee | tee sent &

request_loop &
response_loop

