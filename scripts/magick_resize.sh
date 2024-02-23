#!/bin/bash
########################################################################################################################
#  magick_resize.sh                                                                                                    #
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
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/config.sh"

WIDTH_NAMES=(
    "thumbnail_sq" \
    "thumbnail" \
    "small_sq" \
    "small" \
    "medium" \
    "large" \
    "xlarge" \
    "original" \
)

BOUND_PARAMS=(
    160 \
    160 \
    400 \
    400 \
    800 \
    1200 \
    1920 \
    99999 \
)
USE_GRAVITY="north"

#######################
#  === FUNCTIONS ===  #
#######################

# Common functions
source "${SCRIPT_DIR}/common_funcs.sh"

#  Calculate which of the sizes to use for the image bounding box. 
use_idx() {
    INPUT="${1}"
    FOUND=1

    for (( i=0; i<"${#WIDTH_NAMES[@]}"; i++)); do
        VALID="${WIDTH_NAMES[$i]}"
        if [[ "${VALID}" == "${INPUT}" ]]; then
            FOUND=0
            echo -n "${i}"
            break
        fi
    done

    if [[ "${FOUND}" -ne 0 ]]; then
        logstr "ERROR: Invalid size chosen, using 'original' as default"
        use_idx "original"
    fi
}

#  Returns whether an image should use a square aspect ratio or keep the normal
#  one.
square_up() {
    VALID_SQUARE=(
        "thumbnail_sq" \
        "small_sq"
    )

    INPUT_SIZE="${1}"

    for valid in "${VALID_SQUARE[@]}"; do
        if [[ "${valid}" == "${INPUT_SIZE}" ]]; then
            logstr "Detected square aspect ratio requested"
            return 0
        fi
    done

    logstr "Using normal aspect ratio"
    return 1
}


################################################################################
################################################################################

##################
#  === MAIN ===  #
##################

############
#  INPUTS  #
############

INPUT_IMAGE="${1}"
OUTPUT_IMAGE="${2}"
WIDTH_SELECTOR="${3:-original}"
JPEG_COMPRESSION="${4:-92}"

###############################################################################

####################
#  MAIN EXECUTION  #
####################

# Vallidations of parameters 

if [[ ! -f "${INPUT_IMAGE}" ]]; then
    logstr "ERROR: ${INPUT_IMAGE} not found!"
    exit 1
fi

OUTPUT_DIR="$(dirname "${OUTPUT_IMAGE}")"
check_mkdir "${OUTPUT_DIR}"

# Set up other execution parameters
USE_SIZE_IDX="$(use_idx "${WIDTH_SELECTOR}")"
USE_SIZE="${WIDTH_NAMES[${USE_SIZE_IDX}]}"
BOUND="${BOUND_PARAMS[${USE_SIZE_IDX}]}"

square_up "${USE_SIZE}"
SQUARE=$?

# Handle execution of square cropped images
if [[ "${SQUARE}" -eq 0 ]]; then

    BOUND_PARAM="${BOUND}x${BOUND}^"
    EXTENT_PARAM="${BOUND}x${BOUND}"

    logstr "Resizing ${INPUT_IMAGE} ==> ${OUTPUT_IMAGE}, bound: ${BOUND_PARAM}, square crop"
    logstr "Command: ${CONVERT[@]}" \
        "${INPUT_IMAGE}" \
        -auto-orient \
        -resize "${BOUND_PARAM}" \
        -gravity "${USE_GRAVITY}" \
        -extent "${EXTENT_PARAM}" \
        -quality "${JPEG_COMPRESSION}" \
        "${OUTPUT_IMAGE}"
    "${MAGICK_CONVERT[@]}" \
        "${INPUT_IMAGE}" \
        -auto-orient \
        -resize "${BOUND_PARAM}" \
        -gravity "${USE_GRAVITY}" \
        -extent "${EXTENT_PARAM}" \
        -quality "${JPEG_COMPRESSION}" \
        "${OUTPUT_IMAGE}"

# Handle execution of regular images.
else
    BOUND_PARAM="${BOUND}x${BOUND}>"
    logstr "Resizing ${INPUT_IMAGE} ==> ${OUTPUT_IMAGE}, bound: ${BOUND_PARAM}" 1>&2
    logstr "Command: ${MAGICK_CONVERT[@]}" \
        "${INPUT_IMAGE}" \
        -auto-orient \
        -resize "${BOUND_PARAM}" \
        -quality "${JPEG_COMPRESSION}" \
        "${OUTPUT_IMAGE}"
    "${MAGICK_CONVERT[@]}" \
        "${INPUT_IMAGE}" \
        -auto-orient \
        -resize "${BOUND_PARAM}" \
        -quality "${JPEG_COMPRESSION}" \
        "${OUTPUT_IMAGE}"
fi