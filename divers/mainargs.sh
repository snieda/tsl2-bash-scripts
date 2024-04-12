# MAIN-ARGS by Thomas Schneider / 2024
#
# main-args should be called on start of your shell script to do the following:
# 1. print a help screen with documentation at header and all defined variables,
#    if first arg is something like help (e.g.: --help)
# 2. declare all key-value pairs, given as arguments (like myarg="some value")
#
# usage: source main-args.sh "$@"
#
# Example script:
#   #!/bin/bash
#   #this is my script
#   myfirstvar={myfirstvar:-first}      #first looking at myfirstvar, if not defined, use "first" as default)
#   mysecondvar={mysecondvar:-second}   #first looking at mysecondvar, if not defined use "second"
# Example call:
#   myscript.sh myfirstar=third mysecondvar=nothing

comment_line_count=$(sed '/./d;=;q' $0)
[[ "$1" == *"help" ]] \
   && head -n $comment_line_count $0 \
   && echo "<<main-args by Thomas Schneider / 2024>>" \
   && echo "usage: $0 [[--]help] | [variable overriding arguments...]" \
   && echo "following variables can be overridden and given as arguments:" \
   && sed -rn 's/.*[$][{]([a-zA-Z0-9_]+):-(.*)[}]/\t\1=\t\t\t\2/p' $0 \
   && exit 1

echo "-------------------------------------------------------------------------------"
echo -en "setting variables... "; for a in "$*" ; do [[ "$a" == *"="* ]] && declare -gt $a && shift && echo $a; done; printf "\n"
echo "-------------------------------------------------------------------------------"

