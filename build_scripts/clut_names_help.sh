#!/bin/bash
########################################################################################################################
#  clut_names_help.sh                                                                                                  #
#                                                                                                                      #
#  Copyright (c) 2023 Jason Nishi                                                                                      #
#                                                                                                                      #
#  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated        #
#  documentation files (the “Software”), to deal in the Software without restriction, including without limitation     #
#  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and    #
#  to permit persons to whom the Software is furnished to do so, subject to the following conditions:                  #
#                                                                                                                      #
#  The above copyright notice and this permission notice shall be included in all copies or substantial portions of    #
#  the Software.                                                                                                       #
#                                                                                                                      #
#  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO    #
#  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE      #
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF           #
#  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS   #
#  IN THE SOFTWARE.                                                                                                    #
########################################################################################################################

###################
#  === SETUP ===  #
###################

# Create a temporary working directory and a cleanup function to remove the
# directory at the end of execution.
WORKDIR="$(mktemp -d)"

cleanup() {
    if [[ -d "${WORKDIR}" ]]; then
        rm -rfv "${WORKDIR}"
    fi
}

trap cleanup EXIT


############################
#  === MAIN VARIABLES ===  #
############################

#  N/A

#######################
#  === FUNCTIONS ===  #
#######################

#  Put a nice log string to STDERR
logstr() {
    MSG_STR="${@}"
    OUT_STR="[$(date +"%Y-%m-%dT%H:%M:%S%z")] ${MSG_STR}"
    echo "${OUT_STR}" 1>&2
}

# Get the list of CLUTs from G'MIC
clut_list_text() {

    # State machining:
    #  1 = Looking for the start of the list of CLUTs.
    #  2 = In the list, looking for the end of the list of CLUTs.
    #  3 = After the list. 
    STATE=1
    CAPTURED=""

    # Capture the help text to a text file first, for easy processing, due
    # to weirdness in the help stuff.
    CAPTURE_HELP_FILE="${WORKDIR}/capture_help.txt"
    gmic help clut | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' >"${CAPTURE_HELP_FILE}"

    cat "${CAPTURE_HELP_FILE}" | while read LINE; do
        if [[ ${STATE} -eq 1 ]]; then
            MATCHED="$(echo "${LINE}" | grep -E ".*clut_name.*can.*be.*\{")"
            COUNT="$(echo -n "${MATCHED}" | wc -c)"
            if [[ ${COUNT} -gt 0 ]]; then
                STATE=2
                CUR_CAPTURE="$(echo "${LINE}" | grep -E -o '\{.*' | sed -E 's/^\{//')"
                CAPTURED="${CUR_CAPTURE}"
            fi
        elif [[ ${STATE} -eq 2 ]]; then
            CUR_CAPTURE="$(echo "${LINE}" | grep -E -o '[^\}]*\}?' | head -n 1 | sed -E 's/\}$//')"
            CAPTURED="${CAPTURED} ${CUR_CAPTURE}"

            CHECKER="$(echo "${LINE}" | grep -F -o '}')"
            COUNT="$(echo -n "${CHECKER}" | wc -c)"
            if [[ ${COUNT} -gt 0 ]]; then
                echo -n "${CAPTURED}"
                STATE=3
                break
            fi
        fi
    done  
}

# Take the lines from the help file and turn them into individual item lines
cleanup_clut_list() {
    echo "${1}" | sed -E 's/\|/\n/g' | while read ITEM; do
        echo "${ITEM}" | sed -E -e 's/^\s*//' -e 's/\s$//'
    done
}

################################################################################
################################################################################

##################
#  === MAIN ===  #
##################

OUTPUT_TEXT="${1}"

logstr "Getting list of CLUTs from G'MIC"
FULL_LIST="$(clut_list_text)"
logstr "Cleaning up list of CLUTs and storing in ${OUTPUT_TEXT}"
cleanup_clut_list "${FULL_LIST}" | sort -u > "${OUTPUT_TEXT}"
COUNT="$(cat "${OUTPUT_TEXT}" | wc -l)"
logstr "CLUT list output to ${OUTPUT_TEXT}. Count of CLUTs: ${COUNT}"
