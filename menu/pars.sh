#!/bin/bash
##############################################################################
# pars.sh (Thomas Schneider 2020)
# reads parameters from manual and provides checked arguments to the caller
#
# usage:
# pars <manual> <program-name> <args>
# with:
#  manual:
#    key: argument name (if starting with '-', it is an option/flag without value)
#    val: (*) {format-regex::default-value} description
#
# EXAMPLE 
#   manual:
#      read -d '' MANUAL <<EOF
#      descr   : description of this application
#      file    : (*) {.*::readme.txt} filepath to documentation
#      -l      : log out console
#      EOF
#
#   call: source pars.sh "$MANUAL" $0 "$*"
#
#   use: echo "file is ${VALUES[file]}"
##############################################################################

[ "$1" == "--help" ] || [ "$1" == "" ] && head -n21 $0 && exit 0

# definition block
# DEBUG=y # will print all evaluations
MANUAL="$1"
shift
PROG=${1:-NO-NAME}
shift

# functions

# parameter: 1: MANUAL, 2: PROGNAME
print_help() {
    TITLE="usage for $2\n"
    LINE="==============================================================================\n"
    MANUAL="$TITLE$LINE$1\n\n--help : shows this manual\n$LINE\n"
    printf "$MANUAL"

    echo
}

# evaluate properties of manual
#   parameters: 1: MANUAL
#   return    : arrays: OPTIONS, FORMATS, VALUES
define_variables() {
    declare -Agx OPTIONS DUTIES FORMATS VALUES
    for i in $MANUAL ; do
        case $i in
            :)  if [[ $BEFORE =~ .* ]]; then # not working: [a-z-_.A-Z]+
                    [ ! -z $DEBUG ] && echo "variable name is: $BEFORE"; NAME=$BEFORE;
                else
                    echo "        not matched as name: $BEFORE"
                fi;;
            *==*) continue;;
            -*)  [ ! -z $DEBUG ] && echo "option: $i";
                OPTIONS[$i]="0";;
            \(\*\)) [ ! -z $DEBUG ] && echo "duty: $NAME";
                DUTIES[$NAME]=1;;
            {*}) [ ! -z $DEBUG ] && echo "constraint and default: $i --> CONSTRAINT: ${i%::*} DEFAULT: ${i#*::}";
                TMP=${i%::*}
                FORMATS[$NAME]=${TMP:1};
                TMP=${i#*::}
                VALUES[$NAME]=${TMP%\}}
                ;;
            example*) continue;;
            *)  [ ! -z $DEBUG ] && echo "        >> $i";;
        esac
        BEFORE=$i
    done
}

# reads all arguments to be set as values - if respecting variables constraints
#   parameters: all arguments (like $*)
#   return    : array VALUES
set_values() {
    echo "SET-VALUES: $1"
    declare -ag ERRORS
    for i in $1 ; do
        echo "ARG: $i"
        if [ "${OPTIONS[$i]}" == "0" ]; then
            OPTIONS[$i]=1
            unset -v DUTIES[$NAME]
            echo "     OPTIONS[$i]=1"
        elif [ ${i%=*} != "" ]; then
            declare $i
            NAME=${i%=*}
            VALUE=${i#*=}
            echo "     VALUES[$NAME]=$VALUE"
            if [ "${FORMATS[$i]}" != "" ]; then
                [[ ! $VALUE =~ ${FORMATS[$NAME]} ]] && ERRORS+=("$i must match ${FORMATS[$NAME]}") && continue
                VALUES[$NAME]=$VALUE
                unset -v DUTIES[$NAME]
            fi
        else
            ERRORS+=( "unkown parameter $i" )
        fi
    done
    [ -n "$DUTIES" ] && ERRORS+=("Please provide the following parameters: $(declare -p DUTIES)")
    declare -p OPTIONS VALUES FORMATS DUTIES ERRORS
    [ ! -z $DEBUG ] && print_values
}

# internal print values for debugging
print_values() {
    echo "RESULTS:"
    for i in ${!VALUES[@]}; do
        echo "    $i = ${VALUES[$i]} <-- format: ${FORMATS[$i]}"
    done
    for i in ${!OPTIONS[@]}; do
        echo "    $i = ${OPTIONS[$i]}"
    done

    for i in ${!ERRORS[@]}; do
        echo "ERROR: ${ERRORS[$i]}"
    done
}

# main: assign values
[ "$1" == "--help" ] || [ "$PROG" == "--help" ] && print_help "$MANUAL" "$PROG" && exit 0
[ ! -z $DEBUG ] || [ -n "$ERRORS" ] && print_help "$MANUAL" $PROG

define_variables "$MANUAL"
set_values "$*"

[ -n "$ERRORS" ] && echo "ERRORS: ${ERRORS[@]}" && exit 1

