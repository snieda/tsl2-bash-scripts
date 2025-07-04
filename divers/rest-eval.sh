#!/bin/bash -x
# calls and filters a rest service for each entry in a given file
# UNFINISHED YET / Thomas Schneider 2025
# usage: rest-eval.sh [csv file] [column number of csv] [fieldnames to print]

  SRC_FILE=mainargs.sh
  DIR="${BASH_SOURCE%/*}"
  if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
  if [[ ! -f "$DIR/$SRC_FILE"  && ! -f "~/.local/bin/$SRC_FILE" ]]; then
      [[ -d "~/.local/bin" ]] && BINDIR="~/.local/bin/"
      curl -kL https://github.com/snieda/tsl2-bash-scripts/raw/refs/heads/master/divers/mainargs.sh -o $BINDIR$SRC_FILE && chmod +x $BINDIR$SRC_FILE
  fi
  . $DIR/mainargs.sh || . mainargs.sh

csvfile=${csvfile:-$1}
outputfile="$csvfile.extended.csv"
colnr=${colnr:-0}
url=${url:-https://api.restful-api.dev/objects}
sep="\t"
fields=${fields:-"id name"}
expression=""
replacement=""

# field value is a string surrounded by double quotes
# args: "field name"
str() {
    echo "\\\"$1\\\"[:]\s*\\\"([^\\\"]*)\\\""
}
# field value is a number not surrounded by double quotes
# args: "field name"
num() {
    echo "\\\"$1\\\"[:]\s*([0-9]*)"
}
# only field name will be matched, without grouping it for output
# args: "field name"
lbl() {
    echo "\\\"$1\\\""
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
        [[ "$func" != "lbl" ]] && replacement+="\\$((i++))$sep"
    done
    echo "s/.*$expression/$replacement\\n/p"
}
regex=$(createexpression "$fields")
echo -en "sed expression is: $LGREEN$regex$R\n"
 
[[ -f $outputfile ]] && rm $outputfile
skip_headers=1
i=1
while read -a line
do
    if ((skip_headers)); then ((skip_headers--)); echo -en "$LGREEN${line[*]}$R\n"; continue; fi
    arg=${line[colnr]}
    echo -en "=====> $LBLUE[$((i++)):$colnr]: \"$arg\"$R\n"
    curl  -X 'GET' \
    "$url/$arg" \
    -u '$username:$password' \
    -H 'accept: application/json' \
    | tr '\n' '\f' \
    | sed  -z -E -e "$regex" | tee $outputfile
done < $csvfile
