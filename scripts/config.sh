#!/bin/bash
########################################################################################################################
#  config.sh                                                                                                           #
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

PP3_INFO_FILE_LOCATION="/opt/rawtherapee/pp3_info.json"
GMIC_CLUT_NAMES_FILE_LOCATION="/opt/gmic/clut_names.txt"
GMIC_CLUT_DATA_FILE_LOCATION="/opt/gmic/clut_data.json"
GMIC_SAMPLE_NAMES_FILE_LOCATION="/opt/gmic/sample_names.txt"

# Executables
EXIFTOOL="$(which exiftool)"
MAGICK_CONVERT=("$(which magick)" "convert")
JQ="$(which jq)"
GMIC="$(which gmic)"
RAWTHERAPEE="$(which rawtherapee-cli)"

# Other constants
# AUTOLEVEL_PP3_KEY="AutoLevels_sRGB"
# Using the Auto Matched Curve ISO medium as our auto levelling curve.
AUTOLEVEL_PP3_KEY="Auto-Matched_Curve_-_ISO_Medium"