#!/bin/bash
# calls and filters http services for each entry in an optionally given file or sequence
# (cr) Thomas Schneider 2025
#
# usage: reqs.sh [OPTIONS]
#           [[csvfile=<csv file name>] [csvcol=<column number in csvfile] [csvsep=<seperator in csvfile (default: '\t')]] 
#         | [sequence=<sequence to be used instead of csvfile>]
#           [fields=<response field names to show or simple a regex filter>]
#           [fieldsep=<field seperation in response (default: ':')>]
#           [method=<http method (default:GET)>]
#           [accept=<response accept type (default: application/json)>]
#           [url=<http url to call (variable substition allowed)>) ]
#           [body=<body, if your http method is POST>]
#
# OPTIONS:
#           --help: prints this help and stop
#           --reset: reset all variables
#
# fields:   <name or regex>[§<str|num|lbl|flt>]
#           field names seperated by spaces. on default, the name string will 
#           be enrichted with a regex for key/value pair in json format.
#           :str (default) enrich as json key/value regex for a string
#           :num enrich as json key/value regex for a number
#           :lbl no enrichment. only positional expression for the regex
#           :flt no enrichment. simple regex filter
# method:
#           if you change the http method to e.g. POST, you can give an addtional
#           'body' argument
# examples:
#           - reqs.sh --help
#           - reqs.sh csvfile=mycsvfile.csv csvcol=2 fields="id§num name"
#           - reqs.sh seperator="a b c d" fields="id"
#           - reqs.sh --reset
#           - reqs.sh _args=.args-reqs
#           - reqs.sh _args=.args-reqs dryrun=echo
##############################################################################

  SRC_FILE=mainargs.sh
  DIR="${BASH_SOURCE%/*}"
  if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
  if [[ ! -f "$DIR/$SRC_FILE"  && ! -f ~/.local/bin/"$SRC_FILE" ]]; then
      [[ -d ~/.local/bin ]] && BINDIR=~/.local/bin/
      curl -kL https://github.com/snieda/tsl2-bash-scripts/raw/refs/heads/master/divers/mainargs.sh -o $BINDIR$SRC_FILE && chmod +x $BINDIR$SRC_FILE
  fi
  . ./mainargs.sh || . $DIR/mainargs.sh || . mainargs.sh
  #|| [[ "$_" != "$0" ]] && return 1 2>> /dev/null || exit 1

##############################################################################
# declarations

[[ "$OPTARGS" == *"reset"* ]] && reset

csvfile=${csvfile:-$1}
[[ "$csvfile" != "" ]] && [[ ! -f "$csvfile" ]] && echo -en "$LRED\nFAILED (nothing to do!)$R\n"; [[ "$_" != "$0" ]] && (return 1 2>>/dev/null || exit 1)
outputfile="$csvfile.extended.csv"
csvcol=${csvcol:-0}

method=${method:-GET}
accept=${accept:-"application/json"}
url=${url:-'http://api.restful-api.dev/objects/$arg'}
csvsep=${csvsep:-"\t"}
fields=${fields:-"id name"}
fieldsep=${fieldsep:-"[:]"}
sequence="$(seq 4)"
date=${date:-$(date --iso-8601)}
skip_headers=${skip_headers:-1}
dryrun=${dryrun:-curl}
user=${user:-""}
password=${password:-""}
body=${body:-""}

echo -en "$LBLUE\n"
declare -p csvfile csvsep csvcol outputfile method accept url user password body fields fieldsep sequence
echo -en "$R\n"

expression=""
replacement=""

reset() {
    unset csvfile csvsep csvcol outputfile method accept url user password body fields fieldsep sequence
}
# field value is a string surrounded by double quotes
# args: <field name>
str() {
    echo "\\\"$1\\\"$fieldsep\s*\\\"([^\\\"]*)\\\""
}
# field value is a number not surrounded by double quotes
# args: "field name"
num() {
    echo "\\\"$1\\\"[$fieldsep]\s*([0-9]*)"
}
# only field name will be matched, without grouping it for output
# args: "field name"
lbl() {
    echo "\\\"$1\\\""
}
# filter: similar to lbl, but will be replaced as by str and num
# args: filter regex 
flt() {
    echo "$1"
}

createurl() {
    url0=$1
    while [[ $url0 == *"$"* ]]; do
        url0=$(eval "echo $url0")
    done
    echo " $url0"
}

# args: "space separated fields (default type: str, otherwise add '§num', '§lbl' or '§flt' to field name)"
createexpression() {
    i=1
    for f in $1
    do
        name=${f%§*}
        func=${f#*§}
        [[ "$func" == "$name" ]] && func=str
        # echo "$func($name)"
        expression+="$($func $name).*"
        [[ "$func" != "lbl" ]] && replacement+="\\$((i++))$csvsep"
    done
    echo "s/.*$expression/$replacement\\n/p"
}

##############################################################################
# main routine

if [[ "$csvfile" == "" ]]; then
    if [[ \"$0\" == *\"/usr/bin/\"* ]]; then
        csvfile="reqs.sequence.log"
    else
        csvfile=$0.sequence.log
    fi
    outputfile=$csvfile.result.log
    skip_headers=1
    echo "ID" > $csvfile
    echo "$sequence" >> $csvfile
    echo -en "$LBLUE\nWARN: no csvfile given ==> using 'sequence' definition as content for default csvfile=$csvfile$R\n" 
fi

regex=$(createexpression "$fields")
echo -en "\nsed expression is: $LGREEN$regex$R\n"
[[ ! $(sed -n -z -E -e "$regex" </dev/null) ]] && return 1

[[ -f $outputfile ]] && rm $outputfile
[[ -f $csvfile.log ]] && rm $csvfile.log
i=0
while read -a line
do
    if ((skip_headers)); then ((skip_headers--)); declare -a header=$line; echo -en "\nHEADER: $LGREEN${line[*]}$R\n"; continue; fi
    [[ $line == \#* ]] && continue
    arg=${line[csvcol]}
    url_=$(createurl $url)
    i=$((i+1))
    echo -en "\n=====> $LBLUE[$i:$csvcol]: ${header[$csvcol]}=\"$arg\"$R ==> URL: $LGREEN$url_$R\n" | tee -a $csvfile.log
    [[ "$body" != "" ]] && echo -en "$LGREEN$bold$body$R"

    $dryrun -kL --trace-ascii "$csvfile.trace.log"  -X $method \
    $url_ \
    $( [[ "$body" != "" ]] && echo "-d $body" || echo "") \
    -u "$user:$password" \
    -H "accept: $accept" \
    | tee -a $csvfile.log \
    | tr '\n' '\f' \
    | sed  -n -z -E -e "$regex" | tee -a $outputfile
    
    [[  $? != 0 ]] && echo -en "\n$LRED FAILED ($RESULT)!\n$R" && exit 1
done < $csvfile

[[ -f $outputfile ]] && [[ "$(cat $outputfile)" != "" ]] \
    && echo -en "$LGREEN\n=============================================================================" \
    && echo -en         "\nSUCCESS (findings: $(wc -l < $outputfile) / $i, $(date --iso-8601=seconds))\n\tresult saved in: $outputfile\n\tcurl output    : $csvfile\n\tcurl-trace     : $csvfile.trace.log" \
    && echo -en "$LGREEN\n=============================================================================$R\n" \
    && echo -en "\b" \
    || echo -en "$LRED\nFAILED (nothing found)$R\n"; [[ "$_" != "$0" ]] && return 1 2>>/dev/null || exit 1
