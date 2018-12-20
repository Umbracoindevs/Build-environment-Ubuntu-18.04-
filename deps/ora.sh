#!/bin/bash
_SPINNER_POS=0
_TASK_OUTPUT=""
CYAN=$(tput setaf 6)
NORMAL=$(tput sgr0)
BOLD=$(tput bold)

spinner() {
    _TASK_OUTPUT=""
    local delay=0.05
    local list=( $(echo -e '\xe2\xa0\x8b')
                 $(echo -e '\xe2\xa0\x99')
                 $(echo -e '\xe2\xa0\xb9')
                 $(echo -e '\xe2\xa0\xb8')
                 $(echo -e '\xe2\xa0\xbc')
                 $(echo -e '\xe2\xa0\xb4')
                 $(echo -e '\xe2\xa0\xa6')
                 $(echo -e '\xe2\xa0\xa7')
                 $(echo -e '\xe2\xa0\x87')
                 $(echo -e '\xe2\xa0\x8f'))
    local i=$_SPINNER_POS
    local tempfile
    tempfile=$(mktemp)

    eval $2 >> $tempfile 2>/dev/null &
    local pid=$!

    tput sc
    printf "%s %s" "${list[i]}" "$1"
    tput el
    tput rc

    i=$(($i+1))
    i=$(($i%10))

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        printf "%s" "${CYAN}${list[i]}${NORMAL}"
        i=$(($i+1))
        i=$(($i%10))
        sleep $delay
        printf "\b\b\b"
    done
    _TASK_OUTPUT="$(cat $tempfile)"
    rm $tempfile
    _SPINNER_POS=$i

    if [ -z $3 ]; then :; else
      eval $3=\'"$_TASK_OUTPUT"\'
    fi
}
