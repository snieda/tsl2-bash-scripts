# MAIN-ARGS cr by Thomas Schneider / 2024
#
# main-args should be called on start of your shell script to do the following:
# 1. print a help screen with documentation at header and all defined variables,
#    if first arg is something like help (e.g.: --help)
# 2. collect all options having no '='' to OPTARGS, given as arguments (like -myoption +myoption2")
# 3. declare all key-value pairs, given as arguments (like myarg="some value")
#
# usage: source mainargs.sh "$@"
#
# Example script:
#   #!/bin/bash
#   #this is my script
#   myfirstvar={myfirstvar:-$1   }      #first looking at myfirstvar, if not defined, use first parameter)
#   mysecondvar={mysecondvar:-second}   #first looking at mysecondvar, if not defined use "second"
# Example call:
#   myscript.sh myfirstar=third mysecondvar=nothing
# Tip:
#   if you need a dryrun, prefix your main command with $dryrun - the caller can give an "dryrun=echo "

title=$(
cat <<'EOF'
               .__                                  
  _____ _____  |__| ____ _____ _______  ____  ______
 /     \\__  \ |  |/    \\__  \\_  __ \/ ___\/  ___/
|  Y Y  \/ __ \|  |   |  \/ __ \|  | \/ /_/  >___ \ 
|__|_|  (____  /__|___|  (____  /__|  \___  /____  >
      \/     \/        \/     \/     /_____/     \/ 

EOF
)

echo "starting: $0 $@"
echo "$title"


comment_line_count=$(sed '/./d;=;q' $0)
[[ "$1" == *"help" ]] \
   && head -n $comment_line_count $0 \
   && echo "<<main-args by Thomas Schneider / 2024>>" \
   && echo "usage: $0 [[--]help] | [variable overriding arguments...]" \
   && echo "following variables can be overridden and given as arguments:" \
   && sed -rn 's/.*[$][{]([a-zA-Z0-9_]+):-(.*)[}]/\t\1=\t\t\t\2/p' $0 \
   && exit 1

echo
echo "declared variables:"
sed -rn 's/.*[$][{]([a-zA-Z0-9_]+):-(.*)[}]/\t\1=\t\t\t\2/p' $0

OPTARGS=""
echo "-------------------------------------------------------------------------------"
echo -en "setting options... "; for a in "$@" ; do [[ "$a" != *"="* ]] && OPTARGS="$OPTARGS $a" && shift && echo " $a"; done; printf "\n"
echo "-------------------------------------------------------------------------------"
echo "OPTARGS: \"$OPTARGS\""

echo "-------------------------------------------------------------------------------"
echo -en "setting variables... "; for a in "$@" ; do [[ "$a" == *"="* ]] && declare -gt $a && shift && echo $a; done; printf "\n"
echo "-------------------------------------------------------------------------------"
