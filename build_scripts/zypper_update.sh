#!/bin/bash

zypper refresh
zypper dup -y
zypper update -y
rm -rf /var/cache/zypp/*