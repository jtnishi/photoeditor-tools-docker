########################################################################################################################
#  Dockerfile                                                                                                          #
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

################################################################################
################################################################################

# ########################
# #  === DOWNLOADER ===  #
# ########################

# # Handles downloading custom PP3s to an intermediate docker container so that
# # we can minimize downloads on re-builds.

FROM alpine:latest AS downloader
RUN apk update && apk add git curl
RUN mkdir -p /output/PP3s

# GLTR87
RUN git clone --depth=1 "https://github.com/GLTR87/RawTherapee-presets-Fuji-inspired" /output/PP3s/GLTR87 && rm -rf /output/PP3s/GLTR87/.git

# pixls.us PP3s
RUN git clone --depth=1 "https://github.com/pixlsus/RawTherapee-Presets" /output/PP3s/pixls.us && rm -rf /output/PP3s/pixls.us/.git

# # Stefan Chirila
# REMOVED DOWNLOAD TO MINIMIZE LOAD ON A NON-CONTROLLED SERVER.

################################################################################
################################################################################

######################
#  === BASELINE ===  #
######################

# Builds the basic parts of the container we need for 

FROM opensuse/tumbleweed:latest AS baseline

######################################################
#  BASE UPDATE & INSTALL BASE PACKAGES WE WILL NEED  #
######################################################

# * aws-cli: AWS command line interface. Used for accessing S3-compatible data stores, such as MinIO, or just straight S3.
# * exiftool: EXIFTool by Phil Harvey. Used to update EXIF info in images.
# * ImageMagick: ImageMagick by ImageMagick Studio LLC. A very general photo editing library
# * jq: CLI JSON parser. Used to quickly manipulate JSON files in shell.
# * python310 & python310-pip: Python Programming Language. For scripts & other libraries.
# * rawtherapee: Raw Therapee. RAW Photo Editor
# * gnu_parallel: GNU Parallel. Used to handle multiprocessing runs. Mostly for our build tools.
# * gmic: GREYC's Magic for Image Computing. Used for some photo editing manipulation.
# * less: For help in catting files. Mostly for debug.
# * bc: Basic calculator, for doing some basic math in bash script.

RUN zypper refresh && \
    zypper dup -y && \
    zypper update -y && \
    zypper install -y \
        exiftool \
        ImageMagick \
        jq \
        python3 \
        python3-pip \
        rawtherapee \
        gnu_parallel \
        gmic \
        less \
        bc \
        python3-PyYAML && \
    rm -rf /var/cache/zypp/*

# * PyYAML - YAML parsing library
#RUN pip install PyYAML



##########################
#  HANDLE GMIC UPDATING  #
##########################
RUN gmic up

##########################
#  ADD RAWTHERAPEE PP3s  #
##########################
RUN mkdir -p /opt/rawtherapee/PP3s
COPY --from=downloader /output/PP3s /opt/rawtherapee/PP3s

#####################
#  ADD CUSTOM PP3s  #
#####################
COPY ./PP3s /opt/rawtherapee/PP3s

################################
#  === CALCULATE PP3 INFO ===  #
################################
COPY ./build_scripts/pp3_info.sh /tmp
RUN chmod 755 /tmp/pp3_info.sh && \
    /tmp/pp3_info.sh \
        "/opt/rawtherapee/pp3_info.json" \
        "/opt/rawtherapee/PP3s" \
        "/usr/share/rawtherapee/profiles" && \
    rm /tmp/pp3_info.sh

##################################
#  === CALCULATE CLUT NAMES ===  #
##################################
RUN mkdir -p "/opt/gmic"
COPY ./build_scripts/clut_names_help.sh \
     ./build_scripts/parse_all_cluts_runner.sh \
     ./build_scripts/parse_all_cluts.py \
     /tmp/

RUN chmod 755 \
        /tmp/clut_names_help.sh \
        /tmp/parse_all_cluts_runner.sh \
        /tmp/parse_all_cluts.py && \
    /tmp/parse_all_cluts_runner.sh \
        "/root/gmic" \
        "/opt/gmic/clut_data.json"

COPY ./build_scripts/clut_names_json.sh /tmp/
RUN chmod 755 /tmp/clut_names_json.sh && \
    /tmp/clut_names_json.sh \
        "/opt/gmic/clut_data.json" \
        "/opt/gmic/clut_names.txt" && \
    rm /tmp/clut_names_json.sh

####################################
#  === CALCULATE SAMPLE NAMES ===  #
####################################
RUN mkdir -p "/opt/gmic"
COPY ./build_scripts/sample_names.sh /tmp
RUN chmod 755 /tmp/sample_names.sh && \
    /tmp/sample_names.sh "/opt/gmic/sample_names.txt" && \
    rm /tmp/sample_names.sh

##############################################
#  === PRELOAD SAMPLES/CLUTS FROM G'MIC ===  #
##############################################
# for those network free situations
# TEMPORARILY REMOVING UNTIL WE GET CLOSE TO FINISHED, JUST TO KEEP BUILD TIMES
# SANE
# COPY ./build_scripts/preload_samples_cluts.sh /tmp
# RUN chmod 755 /tmp/preload_samples_cluts.sh && \
#     /tmp/preload_samples_cluts.sh \
#         "/opt/gmic/clut_names.txt" \
#         "/opt/gmic/sample_names.txt" && \
#     rm /tmp/preload_samples_cluts.sh

################################################################################
################################################################################

#####################
#  === TOOLING ===  #
#####################

FROM baseline AS tooling

# @TODO!
RUN echo "TO DO!"

################################################################################
################################################################################

##################
#  === PROD ===  #
##################

FROM baseline AS prod

LABEL version="0.1.0"
LABEL org.opencontainers.image.authors="wonderfish@gmail.com"

# Things to do here!

# Copy in the main runtime scripts to the docker.
#RUN mkdir -p /opt/bin
COPY ./scripts/*.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/*.sh
