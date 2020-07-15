# convenience variables, aliases and methods for styling
E0='\x1b[00;'
E1='\x1b[01;'
C0="$E0$Im"
C1="$EE[01;$Im"
I=30

RESTORE='\x1b[0m'
R=$RESTORE

COLORS="RED GREEN YELLOW BLUE PURPLE CYAN LIGHTGRAY"
for c in $COLORS; do I="$I+1"; declare $c="$C0"; echo "$c=$C0 "; done;

RED='\x1b[00;31m'
GREEN='\x1b[00;32m'
YELLOW='\x1b[00;33m'
BLUE='\x1b[00;34m'
PURPLE='\x1b[00;35m'
CYAN='\x1b[00;36m'
LIGHTGRAY='\x1b[00;37m'

LRED='\x1b[01;31m'
LGREEN='\x1b[01;32m'
LYELLOW='\x1b[01;33m'
LBLUE='\x1b[01;34m'
LPURPLE='\x1b[01;35m'
LCYAN='\x1b[01;36m'
WHITE='\x1b[01;37m'

C_FRM=$BLUE
C_CMD=$LCYAN
C_PAR=$LGREEN
C_CMT=$LRED
