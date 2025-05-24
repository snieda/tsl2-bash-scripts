#!/bin/bash
# MAIN-ARGS cr by Thomas Schneider / 2024
#
# main-args should be called on start of your shell script to do the following:
# 1. print a help screen with documentation at header and all defined variables,
#    if first arg is something like help (e.g.: --help)
# 2. read arguments from file (default: scriptname + '.args') given by first arg '_args=<filename>'
# 3. collect all options having no '='' to OPTARGS (and the array ARGS), given as arguments (like -myoption +myoption2")
# 4. declare all key-value pairs, given as arguments (like myarg="some value")
# 5. extended use with $1 as '_argsfolder': loop over all files in _argsfolder and call $2 (returns with 2)
#    the _argsfolder value MUST HAVE a globstar! (activate globstars with: shopt -s globstar) 
#    usage: <executable-script> _argsfolder=<folder-containing-arg-files-with-globstar> <another-executable-script>
#
# usage:
#   source mainargs.sh [--help|"$@"|_args=<argsfile>|_argsfolder=<folder+filefilter> <script-or-command>] || exit 1
# examples-usages: 
#   source mainargs.sh "$@" || exit 1
#   . mainargs.sh _args=".myargs"      # read arguments through file .myargs (default: .args)
#   . mainargs.sh _argsfolder="**/arguments/*.args"
#
# Example script:
#   #!/bin/bash
#   #this is my script
#   myfirstvar={myfirstvar:-$1   }      #first looking at myfirstvar, if not defined, use first parameter)
#   mysecondvar={mysecondvar:-second}   #first looking at mysecondvar, if not defined use "second"
# Example call:
#   myscript.sh myfirstar=third mysecondvar=nothing
# Tip:
#  - if you need a dryrun, prefix your main command with $dryrun - the caller can give an "dryrun=echo "
#  - you can use the OPTARGS string, holding all options in one string - or ARGS as array
#  - you can set the run arguments again with: ARGS0=( $OPTARGS ); set -- $ARGS0
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

PARENT_COMMAND=$(ps -o comm= $PPID)
echo -en "\nstarting: ${bold}$0 $@ $LYELLOW$bold(parent: $PARENT_COMMAND)\n"
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

# run the given callback ($2) with args given by filenames in folder through $1 as '_argsfolder'
if [[ "$1" == "_argsfolder="* ]]; then
      echo -en "\n$LCYAN$bold>>STARTING LOOP $callback through arguments in FOLDER $argsfolder<<$R\n"
      argsfolder=${1:12}
      callback=$2
      for f in $(ls $argsfolder); do echo "  => $callback \"_args=$f\"" ; $callback "_args=$f"; done
      return 2;
fi

echo "-------------------------------------------------------------------------------"
[[ "$1" == "_args="* ]] && args_file=${1:6} || args_file=".args"
printf "\nreading args from file \"$args_file\"\n"
FILEARGS=()
while IFS='' read -r a || [[ -n "$a" ]]; do [[ "$a" != "#"* ]] && [[ "$a" == *"="* ]] && a=$(eval echo "$a") && FILEARGS+=$a && declare -gt $a && echo -en "$LBLUE$a$R\n"; done < "$args_file"; printf "\n"
echo "-------------------------------------------------------------------------------"

echo
echo "searching for nested variables..."
for a in $FILEARGS ; do
      while [[ $a == *"$"* ]]; do
            a=$(eval echo "$a")
            declare -gt $a
            echo -en "nested -> $LGREEN$a$R\n"            
      done
done

echo
echo "declared variables:"
sed -rn 's/.*[$][{]([a-zA-Z0-9_]+):-(.*)[}]/\t\1=\t\t\t\2/p' $0

OPTARGS=""
ARGS=()
echo "-------------------------------------------------------------------------------"
echo -en "setting options... "; for a in "$@" ; do [[ "$a" != *"="* ]] && OPTARGS="$OPTARGS $a" && ARGS+=($a) && shift && echo " $a"; done; printf "\n"
echo "-------------------------------------------------------------------------------"
echo -en "OPTARGS: \"$LGREEN$OPTARGS$R\"\n"

echo "-------------------------------------------------------------------------------"
echo -en "setting variables... "; for a in "$@" ; do [[ "$a" == *"="* ]] && declare -gt $a && shift && echo -en "$LGREEN$a$R "; done; printf "\n"
echo "-------------------------------------------------------------------------------"
