#!/bin/bash
# Print result of any curl request - using mainargs.sh
# usage: request.sh <[.args (file)] | [url=<url> body=<body> [method=<GET|PUT|POST>] [filter=<regular expression>]]>
#
# the result will be stored in the variable: RESULT_VALUE and written to file request-result.txt

if [[ ! -f "../mainargs.sh" ]]; then
    (cd ../ && curl -kL -O "https://raw.githubusercontent.com/snieda/tsl2-bash-scripts/refs/heads/master/divers/mainargs.sh")
fi
. ../mainargs.sh "$@" || return 1
 
method=${method:-GET}
 
while [[ $url == *"$"* ]]; do
  url=$(eval "echo $url")
done

# check and show json body
# python -mjson.tool "$somefile" > /dev/null
echo -en "url=$LGREEN$bold$url$R"
echo -en "$LGREEN$bold$body$R"
echo
 
curl -kL --trace-ascii request.log -X "$method" "$url" \
  -H "Expect:" \
  -H 'Content-Type: application/json; charset=utf-8' \
  -H 'accept: application/json' \
  -d "$body" | tee $0-response.json
 
RESULT=$?
 
[[  $RESULT == 0 ]] && [[ "$filter" != "" ]] && echo;echo && echo "FILTER: $filter" \
  && export RESULT_VALUE=$(sed -n -E -e "s/.*($filter).*/\1/p" $0-response.json) \
  && echo -en "$LGREEN$bold$RESULT_VALUE$R"
  && echo "$RESULT_VALUE" > $0-result.txt

echo
[[  $RESULT != 0 ]] && echo -en "$LRED FAILED ($RESULT)!" && exit 1
 