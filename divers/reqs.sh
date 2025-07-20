#!/bin/bash
# calls and filters http services for each entry in an optionally given file or sequence.
# usable to generate data files - or to check sites/data for changes.
# to check for changes, use it together with 'watch' and 'diff.'
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
#           --help  : prints this help and stop
#           --reset : reset all variables
#           --silent: reduce output
#
# fields:   <name or regex>[§<str|opt|num|lbl|flt>]
#           if fields starts with 's/' the fields itself will be used as full
#           sed expression like s/<match>/replace/p 
#           field names seperated by spaces. on default, the name string will 
#           be enrichted with a regex for key/value pair in json format.
#           :str (default) enrich as json key/value regex for a string
#           :opt enrich as json key/value regex for an optional string
#           :num enrich as json key/value regex for a number
#           :lbl no enrichment. only positional expression for the regex
#           :flt no enrichment. simple regex filter , replacement may include shell vars
# method:
#           if you change the http method to e.g. POST, you can give an addtional
#           'body' argument
# OTHER:
#           there are some other fields (pointers to methods) to re-define. all of them
#           must be able to get the stdin through a pipe. so you may use
#               declare -i i=${1:-$(</dev/stdin)};
#           as first function line.
#           - runner: default 'curl'
#           - sedrunner: default 'sed'
#           - transformer: default tr '\n' '\f'
#           - callback: default printonly, may be an addtional function call after runner
# examples:
#           - reqs.sh --help
#           - reqs.sh csvfile=mycsvfile.csv csvcol=2 fields="id§num name vorname§opt"
#           - reqs.sh url="xyz$arg" fields='s/a/b/p'
#           - reqs.sh url="xyz${line[0]}" fields='s/a/${line[0]}b/p'
#           - reqs.sh seperator="a b c d" fields="id"
#           - reqs.sh --reset
#           - reqs.sh _args=.args-reqs --silent
#           - reqs.sh _args=.args-reqs runner=echo
#
# note:
#           - nested variables in $url or $field will be inserted! see examples.
#           - $csvcol defines the content of $arg. but you can directly use
#             ${line[<number>]}
#           - be careful with your $filter definition including shell vars:
#             don't use spaces in your replacement expression to avoid a
#             not ended sed expression (cutting on spaces)
#           - to create/generate an input csvfile, use genseq.sh 
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
outputfile="$csvfile.result.csv"
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
runner=${runner:-curl}
sedrunner=${sedrunner:-'sed -n -E -e'} # alternative: 'perl -0777 -pe'
transformer=${transformer:-"tr '\n' '\f'"}
callback="printonly"
user=${user:-""}
password=${password:-""}
body=${body:-""}

echo -en "$LBLUE\n"
declare -p runner sedrunner transformer csvfile csvsep csvcol outputfile method accept url user password body fields fieldsep sequence
echo -en "$R\n"

expression=""
replacement=""

# helper function as default callback 
printonly() {
    #declare -i i=${1:-"$(</dev/stdin)"};
    #echo "$args_: $1"
    echo "$(</dev/stdin)"
}

reset() {
    unset runner sedrunner transformer csvfile csvsep csvcol outputfile method accept url user password body fields fieldsep sequence
}
# field value is a string surrounded by double quotes
# args: <field name>
str() {
    echo "\\\"?$1\\\"?$fieldsep\s*\\\"?([^\\\"]*)\\\"?"
}
opt() {
    echo "(\\\"?$1\\\"?$fieldsep\s*\\\"?(\w+)\\\"?)?"
}
# field value is a number not surrounded by double quotes
# args: "field name"
num() {
    echo "\\\"?$1\\\"?$fieldsep\s*([0-9]*)"
}
# only field name will be matched, without grouping it for output
# args: "field name"
lbl() {
    echo "\\\"?$1\\\"?"
}
# filter: similar to lbl, but will be replaced as by str and num
# args: filter regex 
flt() {
    echo "$1"
}

insertnestedvariables() {
    a1=$1
    while [[ $a1 == *"$"* ]]; do
        a1=$(eval "echo $a1" )
    done
    echo " $a1"
}

# args: "space separated fields (default type: str, otherwise add '§num', '§lbl' or '§flt' to field name)"
createexpression() {
    if [[ "$1" == "s/"* ]]; then
        echo "$1"
        return 0;
    fi
    i=1
    for f in $1
    do
        name=${f%§*}
        func=${f#*§}
        [[ "$func" == "$name" ]] && func=str
        # echo "$func($name)"
        expression+="$($func $name).*?"
        [[ "$func" == "opt" ]] && ((i++))  # as sed is not able to use non-matching groups, we hop over
        [[ "$func" != "lbl" ]] && replacement+="\\$((i++))$csvsep"
    done
    echo "s/.*$expression/\\n$replacement/p"
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
#[[ ! $($sedrunner "$regex" </dev/null) ]] && echo -en "${LRED}error in sed expression$R\n" && return 1

[[ -f $outputfile ]] && rm $outputfile
[[ -f $csvfile.log ]] && rm $csvfile.log
i=0
echo -en "\n$LYELLOW$bold=========================================================================="
echo -en "\nstarting iteration through $csvfile (output: $outputfile)$R\n"
while read -a line
do
    if ((skip_headers)); then ((skip_headers--)); declare -a header=$line; echo -en "\nHEADER: $LGREEN${line[*]}$R\n"; continue; fi
    [[ $line == \#* ]] && continue
    arg=${line[csvcol]}
    url_=$(insertnestedvariables $url)
    regex_=$(insertnestedvariables "\"$regex\"")
    i=$((i+1))
    if [[ ! $OPTARGS == *"--silent"* ]]; then
        echo -en "\n=====> $LBLUE[$i:$csvcol]: ${header[$csvcol]}=\"$arg\"$R ==> URL: $LGREEN$url_\n\t\t\t\tRegEx: $regex_$R\n" | tee -a $csvfile.log
        [[ "$body" != "" ]] && echo -en "$LGREEN$bold$body$R"
    fi
    $runner -kL $(sed -n -E -e 's/(--silent)/\1/p' <<<$OPTARGS) --trace-ascii "$csvfile.trace.log"  -X $method \
    $url_ \
    -d "$body" \
    -u "$user:$password" \
    -H "Authorization: Basic $authorization" \
    -H "accept: $accept" \
    | tee -a $csvfile.log \
    | $transformer \
    | $sedrunner "$regex_" | tee -a $outputfile
    # | $callback         # callback method by caller using pipe as input: declare -i i=${1:-$(</dev/stdin)};
    [[  $? != 0 ]] && echo -en "\n$LRED FAILED ($RESULT)!\n$R" && exit 1
done < $csvfile

[[ -f $outputfile ]] && [[ "$(cat $outputfile)" != "" ]] \
    && echo -en "\n\n=============================================================================\n" \
    && $( [[ ! "$OPTARGS" == *"--silent"* ]] && cat $outputfile >> /dev/stderr || echo >> /dev/stderr ) \
    && echo -en "$LGREEN\n=============================================================================" \
    && echo -en        "\nSUCCESS (findings: $(wc -l < $outputfile) / $i, $(date --iso-8601=seconds))\n\tresult saved in: $outputfile\n\tcurl output    : $csvfile\n\tcurl-trace     : $csvfile.trace.log" \
    && echo -en "$LGREEN\n=============================================================================$R\n" \
    && echo -en "\b" \
    || echo -en "$LRED\nFAILED (nothing found)$R\n"; [[ "$_" != "$0" ]] && return 1 2>>/dev/null || exit 1
