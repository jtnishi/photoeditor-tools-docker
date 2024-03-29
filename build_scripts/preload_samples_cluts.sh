#!/bin/bash
########################################################################################################################
#  preload_samples_cluts.sh                                                                                            #
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

############################
#  === MAIN VARIABLES ===  #
############################

CPU_CORES="$(grep -c processor /proc/cpuinfo)"
GMIC="$(which gmic)"

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

CLUT_LIST_PATH="${1}"
SAMPLES_LIST_PATH="${2}"

USE_CORES="$(( ${CPU_CORES} - 1 ))"
if [[ "${USE_CORES}" -ge 1 ]]; then
    logstr "Using ${USE_CORES} cores to process"
else
    logstr "Using 1 core to process"
    USE_CORES=1
fi

logstr "Preloading all CLUTs"
cat "${CLUT_LIST_PATH}" | \
    parallel --jobs "${USE_CORES}" \
        "${GMIC}" \
            -sample apples \
            +map_clut '{}'

logstr "Preloading all samples"
cat "${SAMPLES_LIST_PATH}" | \
    parallel --jobs "${USE_CORES}" \
        "${GMIC}" \
            -sample '{}'

logstr "Preload completed."


# set +x