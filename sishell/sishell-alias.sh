# convenience variables, aliases and methods for styling
echo "evaluating sishell aliases and methods..."
E0="\x1b[00;"
E1="\x1b[01;"
I=30

COLORS="RED GREEN YELLOW BLUE PURPLE CYAN LIGHTGRAY"
for c in $COLORS; do I="$(($I+1))"; declare -x $c="$E0$I""m"; declare -x "L$c"="$E0$I""m"; echo "L$c=$E1$I""m"; done;

export C_FRM=$LBLUE
export C_CMD=$LCYAN
export C_PAR=$LGREEN
export C_CMT=$LRED
export RESTORE='\x1b[0m'
export R=$RESTORE
