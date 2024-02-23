#!/bin/bash
########################################################################################################################
#  edit_with_clut.sh                                                                                                   #
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

# Check that the LUT is a valid name
check_lut_name() {
    LUT_NAME="${1}"

    LINE_COUNT=$(cat "${GMIC_CLUT_NAMES_FILE_LOCATION}" | \
                     grep -E "^${LUT_NAME}$" | \
                     wc -l)
    test ${LINE_COUNT} -gt 0
}

# Check that the opacity value is a valid value (in range 0.0 - 1.0)
check_opacity_value() {
    INPUT_OPACITY="${1}"

    # https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash/61835747#61835747
    PARSER_REGEX="^[0-9]+([.][0-9]+)?$"

    # For some reason, this test wasn't working with the =~ operator. Switched to using egrep instead.
    # if ! [[ "${INPUT_OPACITY}" =~ "${PARSER_REGEX}" ]]; then
    if [[ $(echo "${INPUT_OPACITY}" | grep -E "${PARSER_REGEX}" | wc -l) -eq 0 ]]; then
        logstr "WARNING: Opacity \"${INPUT_OPACITY}\" not a valid opacity. Using default of 1.0"
        echo -n "1.0"

    # https://stackoverflow.com/questions/8654051/how-can-i-compare-two-floating-point-numbers-in-bash
    elif (( $(echo "${INPUT_OPACITY} < 0.0 || ${INPUT_OPACITY} > 1.0" | bc -l) )); then
        logstr "WARNING: Opacity \"${INPUT_OPACITY}\" not between 0.0 & 1.0. Using default of 1.0"
        echo -n "1.0"
    else
        echo -n "${INPUT_OPACITY}"
    fi
}

calculate_output_params() {
    OUTPUT_PATH="${1}"
    OUTPUT_FN="$(basename -- ${OUTPUT_PATH})"
    EXT_LOWER="$(echo "${OUTPUT_FN##*.}" | tr 'A-Z' 'a-z')"

    case "${EXT_LOWER}" in
        "tif" | "tiff")
            logstr "Detected TIFF output. Using LZW compression, auto data type"
            echo -n "${OUTPUT_PATH},uchar,lzw"
            ;;
        "jpg" | "jpeg")
            logstr "Detected JPG output. Using quality 100"
            echo -n "${OUTPUT_PATH},100"
            ;;
        *)
            logstr "Unknown/non-parametized output format. Just placing output"
            echo -n "${OUTPUT_PATH}"
            ;;
    esac

}

################################################################################
################################################################################

##################
#  === MAIN ===  #
##################

############
#  INPUTS  #
############

SOURCE_IMAGE="${1}"
TARGET_IMAGE="${2}"
LUT_NAME="${3}"
OPACITY="${4:-1.0}"

####################
#  MAIN EXECUTION  #
####################

# Vallidations of parameters 

if [[ ! -f "${SOURCE_IMAGE}" ]]; then
    logstr "ERROR: \"${SOURCE_IMAGE}\" not found!"
    exit 1
fi

check_lut_name "${LUT_NAME}"
if [[ $? -ne 0 ]]; then
    logstr "Invalid LUT name \"${LUT_NAME}\""
    exit 1
fi

OUTPUT_FOLDER="$(dirname "${TARGET_IMAGE}")"
check_mkdir "${OUTPUT_FOLDER}"

OUTPUT_PARAMS="$( calculate_output_params "${TARGET_IMAGE}" )"
OPACITY="$(check_opacity_value "${OPACITY}")"

logstr "Editing image ${SOURCE_IMAGE} -> ${TARGET_IMAGE}, lut: ${LUT_NAME}," \
       "opacity ${OPACITY}"

logstr "Command: ${GMIC}" \
    "-input" \
    "${SOURCE_IMAGE}" \
    "+map_clut" \
    "${LUT_NAME}" \
    "-blend[0,1]" \
    "alpha,${OPACITY},1" \
    "-output" \
    "${OUTPUT_PARAMS}"

"${GMIC}" \
    "-input" \
    "${SOURCE_IMAGE}" \
    "+map_clut" \
    "${LUT_NAME}" \
    "-blend[0,1]" \
    "alpha,${OPACITY},1" \
    "-output" \
    "${OUTPUT_PARAMS}"

if [[ $? -eq 0 ]]; then
    logstr "Image successfully processed to ${TARGET_IMAGE}"
    exit 0
else
    logstr "ERROR: Error in processing ${SOURCE_IMAGE} -> ${TARGET_IMAGE}"
    exit 1
fi