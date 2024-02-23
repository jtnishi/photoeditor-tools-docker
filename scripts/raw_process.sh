#!/bin/bash
########################################################################################################################
#  raw_process.sh                                                                                                      #
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

# Check that the PP3 key is a valid name
check_pp3_key() {
    PP3_KEY="${1}"

    LINE_COUNT=$(jq -r '.[].key' "${PP3_INFO_FILE_LOCATION}" | \
                     grep -E "^${PP3_KEY}$" | \
                     wc -l)
    test ${LINE_COUNT} -gt 0
}

# Convert the PP3 key to the relevant file
pp3_key_to_pp3_file() {
    PP3_KEY="${1}"

    check_pp3_key "${PP3_KEY}"
    if [[ $? -eq 0 ]]; then
        OUTPUT_PATH="$(jq -r \
                       ".[] | select(.key == \"${PP3_KEY}\") | .file_path" \
                       "${PP3_INFO_FILE_LOCATION}")"
        if [[ -f "${OUTPUT_PATH}" ]]; then
            echo -n "${OUTPUT_PATH}"
            return 0
        else
            logstr "ERROR: PP3 file with key ${PP3_KEY} not found"
            return 1
        fi
    fi
}

# Calculate the format switches for the output.
calculate_format_params() {
    OUTPUT_PATH="${1}"
    OUTPUT_FN="$(basename -- ${OUTPUT_PATH})"
    EXT_LOWER="$(echo "${OUTPUT_FN##*.}" | tr 'A-Z' 'a-z')"

    case "${EXT_LOWER}" in
        "tif" | "tiff")
            logstr "Detected TIFF output."
            echo -n "-tz"
            ;;
        "jpg" | "jpeg")
            logstr "Detected JPG output. Using quality 100"
            echo -n "-j100 -js3"
            ;;
        "png")
            logstr "Detected PNG output."
            echo -n "-n"
            ;;

        *)
            logstr "Unknown/non-parametized output format."
            return 1
            ;;
    esac
}

# Calculate what the bit depth switch should be
calculate_bit_depth() {
    OUTPUT_PATH="${1}"
    BIT_DEPTH="${2}"

    OUTPUT_FN="$(basename -- ${OUTPUT_PATH})"
    EXT_LOWER="$(echo "${OUTPUT_FN##*.}" | tr 'A-Z' 'a-z')"

    if [[ "${EXT_LOWER}" == "jpg" || "${EXT_LOWER}" == "jpeg" ]]; then
        logstr "Bit depth for JPEG is 8-bit only"
        BIT_DEPTH="8"
    elif [[ "${BIT_DEPTH}" == "8" || "${BIT_DEPTH}" == "16" ]]; then
        logstr "Bit depth set to ${BIT_DEPTH}-bits"
    else
        logstr "Bit depth not detected. Using 16-bit as default."
        BIT_DEPTH="16"
    fi

    echo -n "-b${BIT_DEPTH}"
}

# Calculate whether to add the auto levelling profile in the chain first.
auto_level_params() {
    USE_AUTO_LEVEL="$(echo "${1}" | tr 'A-Z' 'a-z')"

    case "${USE_AUTO_LEVEL}" in
        "t" | "true")
            logstr "Detected use auto-level"
            AUTO_LEVEL_PATH="$(pp3_key_to_pp3_file "${AUTOLEVEL_PP3_KEY}")"            
            echo -n "${AUTO_LEVEL_PATH}"
            ;;
        "f" | "false")
            logstr "Detected no auto-level"
            echo -n ""
            ;;
        *)
            logstr "No detected value for auto-level input: ${USE_AUTO_LEVEL}. Defaulting false"
            echo -n ""
            ;;
    esac
}

# IFS=" " read -r -a B <<< "$a"

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
PP3_NAME="${3}"
ADD_AUTO_LEVEL="${4:-false}"
BIT_DEPTH="${5:-16}"

####################
#  MAIN EXECUTION  #
####################

# Vallidations of parameters 

if [[ ! -f "${SOURCE_IMAGE}" ]]; then
    logstr "ERROR: \"${SOURCE_IMAGE}\" not found!"
    exit 1
fi

check_pp3_key "${PP3_NAME}"
if [[ $? -ne 0 ]]; then
    logstr "Invalid PP3 name \"${LUT_NAME}\""
    exit 1
fi

OUTPUT_FOLDER="$(dirname "${TARGET_IMAGE}")"
check_mkdir "${OUTPUT_FOLDER}"

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###



logstr "Editing image ${SOURCE_IMAGE} -> ${TARGET_IMAGE}, PP3: ${PP3_NAME}," \
       "Add Auto Level ${ADD_AUTO_LEVEL}, bit depth ${BIT_DEPTH}"


# Build up the command parameters
COMMAND_PARAMS=()

# Adding output
COMMAND_PARAMS+=("-o" "${TARGET_IMAGE}")

# Adding file format
FORMAT_STR="$(calculate_format_params "${TARGET_IMAGE}")"
read -r -a FORMAT_ARRAY <<< "${FORMAT_STR}"
COMMAND_PARAMS+=("${FORMAT_ARRAY[@]}")

# Adding bit-depth
COMMAND_PARAMS+=("$(calculate_bit_depth "${TARGET_IMAGE}" "${BIT_DEPTH}")")

# Adding default profile into edit chain.
COMMAND_PARAMS+=("-d")

# Adding auto level profile if needed
AUTO_LEVEL_CHECK="$(auto_level_params "${ADD_AUTO_LEVEL}")"
if [[ -n "${AUTO_LEVEL_CHECK}" ]]; then
    COMMAND_PARAMS+=("-p" "${AUTO_LEVEL_CHECK}")
fi

# Add normal profile.
COMMAND_PARAMS+=("-p" "$(pp3_key_to_pp3_file "${PP3_NAME}")")

# Add in the overwrite flag.
COMMAND_PARAMS+=("-Y")

# And finally, add in the main input
COMMAND_PARAMS+=("-c" "${SOURCE_IMAGE}")

logstr "Command: ${RAWTHERAPEE}" \
            "${COMMAND_PARAMS[@]}"

"${RAWTHERAPEE}" \
    "${COMMAND_PARAMS[@]}"


if [[ $? -eq 0 ]]; then
    logstr "Image successfully processed to ${TARGET_IMAGE}"
    exit 0
else
    logstr "ERROR: Error in processing ${SOURCE_IMAGE} -> ${TARGET_IMAGE}"
    exit 1
fi