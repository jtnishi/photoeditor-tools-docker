#!/bin/bash
########################################################################################################################
#  pp3_info.sh                                                                                                         #
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

#  Calculate the checksum string for the file
calc_checksum() {
    FILE_PATH="${1}"
    if [[ -f "${FILE_PATH}" ]]; then
        CHECKSUM="$(sha256sum --binary "${FILE_PATH}" | awk '{print $1}')"
        echo -n "sha256:${CHECKSUM}"
    fi
}

#  Calculate a nice slug string for the file
calc_slug() {
    SLUGIFY_STR="${1}"
    echo -n "${SLUGIFY_STR}" | \
        sed --regexp-extended 's/[^A-Za-z0-9\-\_]/_/g'
}

#  Calculate the relative path for a file.
calc_relpath() {
    FILE_PATH="${1}"
    BASE_PATH="${2}"

    if [[ -f "${FILE_PATH}" ]]; then
        realpath --canonicalize-missing --relative-to="${BASE_PATH}" "${FILE_PATH}"
    fi
}

#  Calulate the information for a single input file
calc_info() {
    FILE_PATH="${1}"
    BASE_PATH="${2}"

    FILENAME="$(basename "${FILE_PATH}")"
    RELPATH="$(calc_relpath "${FILE_PATH}" "${BASE_PATH}")"
    CHECKSUM="$(calc_checksum "${FILE_PATH}")"
    SLUG="$(calc_slug "${RELPATH}")"

    # https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/
    jq \
        --null-input \
        --compact-output \
        --arg filepath "${FILE_PATH}" \
        --arg relpath "${RELPATH}" \
        --arg checksum "${CHECKSUM}" \
        --arg slug "${SLUG}" \
        --arg filename "${FILENAME}" \
        '{"file_path": $filepath, "relpath": $relpath, "checksum": $checksum, "key": $slug, "file_name": $filename}'
}

#  Calculate the information for all key files in the main path.
calc_all_infos() {
    CAPTURE_FILE="${1}"
    SEARCH_PATH="${2}"
    SEARCH_PATTERN="${3}"

    find "${SEARCH_PATH}" -type f -name "${SEARCH_PATTERN}" | \
        while read CURFILE; do
            logstr "Getting information for ${CURFILE}"
            calc_info "${CURFILE}" "${SEARCH_PATH}" >> "${CAPTURE_FILE}"
        done
}

#  Take the generated list of calculated informations and generate a final
#  JSON with the data.
generate_final_json() {
    INPUT_FILE="${1}"
    OUTPUT_FILE="${2}"

    jq --slurp '.' "${INPUT_FILE}" > "${OUTPUT_FILE}"
}


################################################################################
################################################################################

##################
#  === MAIN ===  #
##################

main_func() {
    OUTPUT_JSON="${1}"
    PP3_SEARCH_DIR="${2}"

    logstr "Starting search for PP3 files in folder ${PP3_SEARCH_DIR}"
    TEMP_OUTPUT="${WORKDIR}/capture.jsonlines.txt"
    calc_all_infos "${TEMP_OUTPUT}" "${PP3_SEARCH_DIR}" "*.pp3"
    LINE_COUNT="$(cat "${TEMP_OUTPUT}" | wc -l)"
    logstr "Total found PP3s: ${LINE_COUNT}"

    logstr "Generating output JSON of data at ${OUTPUT_JSON}"
    generate_final_json "${TEMP_OUTPUT}" "${OUTPUT_JSON}"

    logstr "Completed output JSON for PP3 files."
}

main_func "${1}" "${2}"
