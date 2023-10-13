#!/bin/bash
########################################################################################################################
#  exif_json_data.sh                                                                                                   #
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

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/config.sh"

#######################
#  === FUNCTIONS ===  #
#######################

# Common functions
source "${SCRIPT_DIR}/common_funcs.sh"

################################################################################
################################################################################

##################
#  === MAIN ===  #
##################

############
#  INPUTS  #
############

SOURCE_IMAGE="${1}"
OUTPUT_JSON="${2}"

####################
#  MAIN EXECUTION  #
####################

# Vallidations of parameters 

if [[ ! -f "${SOURCE_IMAGE}" ]]; then
    logstr "ERROR: ${SOURCE_IMAGE} not found!"
    exit 1
fi

OUTPUT_FOLDER="$(dirname "${OUTPUT_JSON}")"
if [[ ! -d "${OUTPUT_FOLDER}" ]]; then
    logstr "Making folder ${OUTPUT_FOLDER}"
    mkdir -p "${OUTPUT_FOLDER}"
fi

logstr "Gathering EXIF and image data from ${SOURCE_IMAGE} -> ${OUTPUT_JSON}"

"${EXIFTOOL}" \
        -json \
        -groupHeadings \
        "${SOURCE_IMAGE}" | \
    "${JQ}" '.[0]' > "${OUTPUT_JSON}"

logstr "Image data written to ${OUTPUT_JSON}"
