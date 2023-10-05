#!/bin/bash
########################################################################################################################
#  magick_resize_set.sh                                                                                                #
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

# Core variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}/config.sh"

TARGET_SIZES=(
    "thumbnail_sq" \
    "small" \
    "small_sq" \
    "large" \
    "original"
)

RESIZE_SCRIPT="${SCRIPT_DIR}/magick_resize.sh"
STRIP_EXIF_SCRIPT="${SCRIPT_DIR}/strip_exif.sh"

#######################
#  === FUNCTIONS ===  #
#######################

# Common functions
source "${SCRIPT_DIR}/common_funcs.sh"

# New filename for the output image.
new_filename() {
    INPUT_FN="${1}"
    OUTPUT_FOLDER="${2}"
    SIZE="${3}"

    BASE="$(basename -- "${INPUT_FN}")"
    BASE_NO_EXT="${BASE%%.*}"

    NEW_FN="${OUTPUT_FOLDER}/${BASE_NO_EXT}_${SIZE}.jpg"

    echo -n "${NEW_FN}"
}


################################################################################
################################################################################

##################
#  === MAIN ===  #
##################

INPUT_IMAGE="${1}"
OUTPUT_FOLDER="${2}"

###############################################################################

####################
#  MAIN EXECUTION  #
####################

# Vallidations of parameters 

if [[ ! -f "${INPUT_IMAGE}" ]]; then
    logstr "ERROR: ${INPUT_IMAGE} not found!"
    exit 1
fi

if [[ ! -d "${OUTPUT_FOLDER}" ]]; then
    logstr "Making directory: ${OUTPUT_FOLDER}"
    mkdir -p "${OUTPUT_FOLDER}"
fi

# Run resize for each size.
logstr "Resizing ${INPUT_IMAGE} into multiple sizes into ${OUTPUT_FOLDER}"
for size in "${TARGET_SIZES[@]}"; do
    TARGET="$(new_filename "${INPUT_IMAGE}" "${OUTPUT_FOLDER}" "${size}")"
    if [[ -f "${TARGET}" ]]; then
        logstr "WARNING: Target file ${TARGET} exists, not overwriting."
    else
        logstr "Creating ${INPUT_IMAGE} => ${TARGET}, size ${size}"
        "${RESIZE_SCRIPT}" \
            "${INPUT_IMAGE}" \
            "${TARGET}" \
            "${size}" \
            "${JPEG_COMPRESSION}"

        if [[ "${size}" != "original" ]]; then
            logstr "Removing EXIF tags for non-original images"
            "${STRIP_EXIF_SCRIPT}" "${TARGET}"
        fi
    fi
done

