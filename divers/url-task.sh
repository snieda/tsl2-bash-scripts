#!/bin/bash
##############################################################################
# procurl (Thomas Schneider / 07-2023)
#
# does a whole job on a remote url (on construction!)
#
# 1. go to login url
# 2. login / authenticate
# 3. find page to work on
# 4. do your job on that page
# 5. logoff
#
# usage: $0 url=<target-url-with-vars> loop=<varname:<comma-sep-value-list>> <vars-key-values> [regex-filter] [<regex>=<colorname>...]
#   with:
#      target-url-with-vars: e.g.: "https://page.de/$SUBPAGE/&page=$LOOP" LOOP="1,2,3,4"
##############################################################################

title=<<EOF
 ____ ___ ____  _          _ _ 
/ ___|_ _/ ___|| |__   ___| | |
\___ \| |\___ \| '_ \ / _ \ | |
 ___) | | ___) | | | |  __/ | |
|____/___|____/|_| |_|\___|_|_|
                               
EOF

echo "starting: $0 $@"
[ "$1" == "" ] || [ "$1" == "--help" ] && head -n 20 $0 && exit 1
echo -en "setting parameters: "; for a in "$*" ; do [[ "$a" == *"="* ]] && declare -gt $a && echo $a; done;

SELF=$(basename $0); SELF=${SELF%.*};
[ "$log" == "true" ] && echo() { printf "%s\n" $* | tee -a $ENV_DIR/$SELF.log; }

