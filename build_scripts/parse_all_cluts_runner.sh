#!/bin/bash
########################################################################################################################
#  parse_all_cluts_runner.sh                                                                                           #
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

# set -x

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

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CLUT_LIST_TEXT_PATH="${WORKDIR}/clut_list_help.txt"

#######################
#  === FUNCTIONS ===  #
#######################

#  Put a nice log string to STDERR
logstr() {
    MSG_STR="${@}"
    OUT_STR="[$(date +"%Y-%m-%dT%H:%M:%S%z")] ${MSG_STR}"
    echo "${OUT_STR}" 1>&2
}

#  Get the path to the G'MIC update file downloaded from the server.
gmic_update_path() {
    SEARCH_DIR="${1}"
    PATH_TO_GMIC="$(find "${SEARCH_DIR}" -name '*.gmic' | head -n 1)"
    if [[ ! -f "${PATH_TO_GMIC}" ]]; then
        logstr "ERROR: path to G'MIC update file not found!"
        exit 1
    fi
    echo -n "${PATH_TO_GMIC}"
}

################################################################################
################################################################################

##################
#  === MAIN ===  #
##################

GMIC_UPDATE_SEARCH_DIR="${1}"
OUTPUT_JSON="${2}"

# Get list of CLUTs from G'MIC using side script
"${SCRIPT_DIR}/clut_names_help.sh" "${CLUT_LIST_TEXT_PATH}"

# logstr "List of CLUTs from help follows:"
# cat "${CLUT_LIST_TEXT_PATH}" | sed 's/^/  * /' 1>&2
# printf '=%.0s' {1..80} 1>&2
# echo "" 1>&2

# Get the GMIC update path
GMIC_UPDATE_PATH="$(gmic_update_path "${GMIC_UPDATE_SEARCH_DIR}")"

logstr "Parsing GMIC update to get CLUT information file"
# "${SCRIPT_DIR}/parse_all_cluts.py" \
#     "${GMIC_UPDATE_PATH}" \
#     "${CLUT_LIST_TEXT_PATH}" \
#     "${OUTPUT_JSON}" \
#     --debug
"${SCRIPT_DIR}/parse_all_cluts.py" \
    "${GMIC_UPDATE_PATH}" \
    "${CLUT_LIST_TEXT_PATH}" \
    "${OUTPUT_JSON}"

logstr "CLUT data output to ${OUTPUT_JSON}."


# set +x