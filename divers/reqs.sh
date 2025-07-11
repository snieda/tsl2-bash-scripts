#!/bin/bash
# calls and filters http services for each entry in an optionally given file or sequence
# (cr) Thomas Schneider 2025
#
# usage: reqs.sh [OPTIONS]
#           [[csvfile=<csv file name>] [colnr=<column number in csvfile] [csvsep=<seperator in csvfile (default: '\t')]] 
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
# fields:   <name or regex>[:<str|num|lbl|flt>]
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
#           - reqs.sh csvfile=mycsvfile.csv colnr=2 fields="id name"
#           - reqs.sh seperator="a b c d" fields="id"
#           - reqs.sh --reset
##############################################################################

  SRC_FILE=mainargs.sh
  DIR="${BASH_SOURCE%/*}"
  if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
  if [[ ! -f "$DIR/$SRC_FILE"  && ! -f "~/.local/bin/$SRC_FILE" ]]; then
      [[ -d "~/.local/bin" ]] && BINDIR="~/.local/bin/"
      curl -kL https://github.com/snieda/tsl2-bash-scripts/raw/refs/heads/master/divers/mainargs.sh -o $BINDIR$SRC_FILE && chmod +x $BINDIR$SRC_FILE
  fi
  . mainargs.sh || . $DIR/mainargs.sh 
  #|| [[ "$_" != "$0" ]] && return 1 2>> /dev/null || exit 1

##############################################################################
# declarations

[[ "$OPTARGS" == *"reset"* ]] && reset

csvfile=${csvfile:-$1}
[[ "$csvfile" != "" ]] && [[ ! -f "$csvfile" ]] && echo -en "$LRED\nFAILED (nothing to do!)$R\n"; [[ "$_" != "$0" ]] && (return 1 2>>/dev/null || exit 1)
outputfile="$csvfile.extended.csv"
colnr=${colnr:-0}

method=${method:-GET}
accept=${accept:-"application/json"}
url=${url:-'http://api.restful-api.dev/objects/$arg'}
csvsep=${csvsep:-"\t"}
fields=${fields:-"id name"}
fieldsep=${fieldsep:-"[:]"}
sequence="$(seq 4)"

echo -en "$LBLUE\n"
declare -p csvfile csvsep colnr outputfile method accept url user password body fields sequence
echo -en "$R\n"

expression=""
replacement=""

reset() {
    unset csvfile csvsep colnr outputfile method accept url user password body fields sequence
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
    echo "\\\"$1\\\""
}

createurl() {
    url0=$1
    while [[ $url0 == *"$"* ]]; do
        url0=$(eval "echo $url0")
    done
    echo $url0
}

# args: "space separated fields (default type: str, otherwise add ':num' or ':lbl' to field name)"
createexpression() {
    i=1
    for f in $1
    do
        name=${f%:*}
        func=${f#*:}
        [[ "$func" == "$name" ]] && func=str
        # echo "$func($name)"
        expression+="$($func $name).*"
        [[ "$func" != "lbl" ]] && replacement+="\\$((i++))$csvsep"
    done
    echo "s/.*$expression/$replacement\\n/p"
}

##############################################################################
# main routine

[[ -f $0-fields.log ]] && rm $0-fields.log
skip_headers=1
if [[ "$csvfile" == "" ]]; then
    csvfile=$0-fields.log
    outputfile=$csvfile.extended.log
    skip_headers=0

    echo "$sequence" > $csvfile
    echo -en "$LBLUE\nWARN: no csvfile given ==> using 'sequence' definition as content for default csvfile=$csvfile$R\n" 
fi

regex=$(createexpression "$fields")
echo -en "sed expression is: $LGREEN$regex$R\n"
 
[[ -f $outputfile ]] && rm $outputfile
[[ -f $csvfile.log ]] && rm $csvfile.log
i=1
while read -a line
do
    if ((skip_headers)); then ((skip_headers--)); declare -a header=$line; echo -en "$LGREEN${line[*]}$R\n"; continue; fi
    [[ $line == \#* ]] && continue
    arg=${line[colnr]}
    url_=$(createurl $url)
    echo -en "=====> $LBLUE[$((i++)):$colnr]: ${header[$colnr]}=\"$arg\"$R ==> $LGREEN$url_$R\n"
    [[ "$body" != "" ]] && echo -en "$LGREEN$bold$body$R"

    curl -kL --trace-ascii "$csvfile.trace.log" --silent -X 'GET' \
    "$url_" \
    -d "$body" \
    -u "$username:$password" \
    -H "accept: $accept" \
    | tee -a $csvfile.log \
    | tr '\n' '\f' \
    | sed  -z -E -e "$regex" | tee -a $outputfile
    
    [[  $? != 0 ]] && echo -en "\n$LRED FAILED ($RESULT)!\n$R" && exit 1
done < $csvfile

[[ -f $outputfile ]] && [[ "$(cat $outputfile)" != "" ]] \
    && echo -en "$LGREEN\nSUCCESS (result saved in $outputfile)$R\n" \
    && echo -en "\b" \
    || echo -en "$LRED\nFAILED (nothing found)$R\n"; [[ "$_" != "$0" ]] && return 1 2>>/dev/null || exit 1
