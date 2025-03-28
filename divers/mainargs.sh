# MAIN-ARGS cr by Thomas Schneider / 2024
#
# main-args should be called on start of your shell script to do the following:
# 1. print a help screen with documentation at header and all defined variables,
#    if first arg is something like help (e.g.: --help)
# 2. read arguments from file (default: scriptname + '.args') given by first arg '_args=<filename>'
# 3. collect all options having no '='' to OPTARGS, given as arguments (like -myoption +myoption2")
# 4. declare all key-value pairs, given as arguments (like myarg="some value")
#
# usage: source mainargs.sh "$@" || exit 1
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
#
# generic way to include source script through BASH_SOURCE:
# ---------------------------------------------------------
#   SRC_FILE=mainargs.sh
#   DIR="${BASH_SOURCE%/*}"
#   if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
#   if [[ ! -f "$DIR/$SRC_FILE"  && ! -f "~/.local/bin/$SRC_FILE" ]]; then
#       [[ -d "~/.local/bin" ]] && BINDIR="~/.local/bin/"
#       curl -kL https://github.com/snieda/tsl2-bash-scripts/raw/refs/heads/master/divers/mainargs.sh -o $BINDIR$SRC_FILE && chmod +x $BINDIR$SRC_FILE
#   fi
#   . $DIR/mainargs.sh || . mainargs.sh
# ---------------------------------------------------------

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

# convenience variables, aliases and methods for styling
E0="\x1b[00;"; E1="\x1b[01;"; I=30
bold=$(tput bold); normal=$(tput sgr0)

COLORS="RED GREEN YELLOW BLUE PURPLE CYAN LIGHTGRAY"
for c in $COLORS; do I="$(($I+1))"; declare -x $c="$E0$I""m"; declare -x "L$c"="$E0$I""m"; done;
export R='\x1b[0m'

echo -en "starting: ${bold}$0 $@ $LYELLOW$bold\n"
echo "$title"
echo -en "$R"

comment_line_count=$(sed '/./d;=;q' $0)
if [[ "$1" == *"help" ]]; then \
   head -n $comment_line_count $0 \
   && echo "<<main-args by Thomas Schneider / 2024>>" \
   && echo "usage: $0 [[--]help] | [variable overriding arguments...]" \
   && printf "\nfollowing variables can be overridden and given as arguments:\n" \
   && sed -rn 's/.*[$][{]([a-zA-Z0-9_]+):-(.*)[}]/\t\1=\t\t\t\2/p' $0 \
   && return 1 2> /dev/null || exit 1
fi

echo "-------------------------------------------------------------------------------"
[[ "$1" == *"_args="* ]] && args_file=${1:6} || args_file="$1.args"
printf "\nreading args from file \"$args_file\"\n"
while IFS='' read -r a || [[ -n "$a" ]]; do [[ "$a" == *"="* ]] && declare -gt $a && echo -en "$LBLUE$a$R\n"; done < "$args_file"; printf "\n"
echo "-------------------------------------------------------------------------------"

echo
echo "declared variables:"
sed -rn 's/.*[$][{]([a-zA-Z0-9_]+):-(.*)[}]/\t\1=\t\t\t\2/p' $0

OPTARGS=""
echo "-------------------------------------------------------------------------------"
echo -en "setting options... "; for a in "$@" ; do [[ "$a" != *"="* ]] && OPTARGS="$OPTARGS $a" && shift && echo " $a"; done; printf "\n"
echo "-------------------------------------------------------------------------------"
echo -en "OPTARGS: \"$LGREEN$OPTARGS$R\"\n"

echo "-------------------------------------------------------------------------------"
echo -en "setting variables... "; for a in "$@" ; do [[ "$a" == *"="* ]] && declare -gt $a && shift && echo -en "$LGREEN$a$R "; done; printf "\n"
echo "-------------------------------------------------------------------------------"
