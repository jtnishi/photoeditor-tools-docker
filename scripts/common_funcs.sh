#!/bin/bash
########################################################################################################################
#  common_funcs.sh                                                                                                     #
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

#######################
#  === FUNCTIONS ===  #
#######################

#  Put a nice log string to STDERR
logstr() {
    MSG_STR="${@}"
    OUT_STR="[$(date +"%Y-%m-%dT%H:%M:%S%z")] ${MSG_STR}"
    echo "${OUT_STR}" 1>&2
}

#  Checks if a directory exists, creates otherwise.
check_mkdir() {
    TARGET_DIR="${1}"
    if [[ ! -d "${TARGET_DIR}" ]]; then
        logstr "Making directory ${TARGET_DIR}"
        mkdir -p "${TARGET_DIR}"

        if [[ ! -d "${TARGET_DIR}" ]]; then
            logstr "ERROR: Could not make directory ${TARGET_DIR}"
            return 1
        fi

        return 0
    fi
}

# Check for a boolean value.
check_bool() {
    SWITCH_VAL="${1}"
    DEFAULT_VAL="${2:false}"

    if [[ -z "${SWITCH_VAL}" ]]; then
        check_bool "${DEFAULT_VAL}"
        return $?
    fi

    TEST_STR="$(echo ${SWITCH_VAL} | tr 'A-Z' 'a-z' | xargs echo)"

    case "${TEST_STR}" in
        "true" | "t" | "y")
            return 0
            ;;
        "false" | "f" | "n")
            return 1
            ;;
        *)
            logstr "ERROR: Unknown value '${TEST_STR}' passed in. Using default (${DEFAULT_VAL})"
            check_bool "${DEFAULT_VAL}"
            return $?
            ;;
    esac
}
