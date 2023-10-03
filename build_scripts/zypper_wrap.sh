#!/bin/bash

set -ex

zypper refresh
zypper "$@"
rm -rf /var/cache/zypp/*

set +ex