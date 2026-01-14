#!/bin/bash
# Copyright (C) 2023-2024 Unitrix Kernel

set -e

# Filter in precise actions
function parse_parameters()
{
    while (($#)); do
        case $1 in
		stable | devel | v*) action=$1 ;;
		*) exit 33 ;;
	esac
	shift
    done
}

# Checkout branch of last release
function do_stable()
{
   if ! [ -d $RKSU ]; then
       git clone https://github.com/rsuntk/KernelSU.git $RKSU > /dev/null 2>&1
       git -C $RKSU checkout $(git -C $RKSU describe --abbrev=0 --tags) > /dev/null 2>&1
   fi
}

# Checkout main development branch
function do_devel()
{
   if ! [ -d $RKSU ]; then
       git clone https://github.com/rsuntk/KernelSU.git $RKSU > /dev/null 2>&1
   fi
}

# Checkout any specific older release
function do_older()
{
   if ! [ -d $RKSU ]; then
       git clone https://github.com/rsuntk/KernelSU.git $RKSU > /dev/null 2>&1
       git -C $RKSU checkout $action > /dev/null 2>&1
   fi
}

# Remove existing kernelsu directory
rm -rf $RKSU

# Parse user parameters
parse_parameters $@

# Check action and call appropriate function
if [ $action = "stable" ] || [ $action = "devel" ]; then
do_$action
else
do_older
fi
rm -rf drivers/kernelsu/Kconfig
cp $RKSU/kernel/Kconfig drivers/kernelsu/
