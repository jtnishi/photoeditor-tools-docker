#!/bin/bash
########################################################################################################################
#  clut_names_json.sh                                                                                                  #
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

################################################################################
################################################################################

##################
#  === MAIN ===  #
##################

INPUT_JSON="${1}"
OUTPUT_TEXT="${2}"

logstr "Getting list of CLUT IDs from G'MIC via processed file"
jq -r '.[].lut_id' "${INPUT_JSON}" | sort -u > "${OUTPUT_TEXT}"
COUNT="$(cat "${OUTPUT_TEXT}" | wc -l)"
logstr "CLUT list output to ${OUTPUT_TEXT}. Count of CLUTs: ${COUNT}"